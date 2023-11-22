use super::EventStore;
use crate::types::{Error, EventId, KnownEvent};
use rusqlite::{params, Connection, Error as SqliteError, OptionalExtension};
use serde::{de::DeserializeOwned, Serialize};
use std::fmt::Debug;
use std::marker::PhantomData;
use uuid::Uuid;

/// Events will be stored in a Sqlite database found at `file`, in a table named `table`.
///
/// The table will have two columns: one UUID, and one JSON field.
pub struct SqliteEventStore<Event> {
    file: String,
    table: String,
    phantom: PhantomData<Event>,
}

impl<Event> SqliteEventStore<Event> {
    /// Create a new `SqliteEventStore` that will read and write events from the specified file and table.
    ///
    /// This will create the table if it does not yet exist.
    /// No checks are made to check the table has the correct structure.
    pub fn new(file: &str, table: &str) -> Result<Self, SqliteError> {
        let store = Self {
            file: file.to_string(),
            table: table.to_string(),
            phantom: PhantomData,
        };

        store.create_table()?;

        Ok(store)
    }

    fn get_conn(&self) -> Result<Connection, SqliteError> {
        Connection::open(&self.file)
    }

    fn create_table(&self) -> Result<(), SqliteError> {
        let conn = &self.get_conn()?;
        let create_table_query = format!(
            "CREATE TABLE IF NOT EXISTS {} (
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          uuid BLOB CHECK(length(uuid) = 16) UNIQUE NOT NULL,
          payload TEXT NOT NULL
      )",
            &self.table
        );
        conn.execute(&create_table_query, ())?;
        Ok(())
    }

    fn get_id_from_uuid(&self, uuid: Uuid) -> Result<i64, SqliteError> {
        self.get_conn()?
            .prepare(&format!(
                "SELECT id FROM {} WHERE uuid = ? LIMIT 1",
                &self.table
            ))
            .and_then(|mut stmt| stmt.query_row([uuid], |row| row.get::<_, i64>("id")))
    }
}

impl<Event> EventStore<Event> for SqliteEventStore<Event>
where
    Event: Serialize + DeserializeOwned + Debug,
{
    fn publish(&self, uuid: Uuid, event: Event) -> Result<EventId, Error> {
        let json = serde_json::to_string(&event).map_err(|err| {
            Error::JsonSerialiseError(
                err,
                String::from("Failed to serialise event during publish()"),
            )
        })?;
        self.get_conn()
            .and_then(|conn| {
                conn.execute(
                    &format!("INSERT INTO {} (uuid, payload) VALUES (?, ?)", &self.table),
                    params![uuid, json],
                )
            })
            .map_err(|err| {
                Error::SqliteError(
                    err,
                    format!("Failed to publish event to table {}", self.table),
                )
            })?;

        Ok(uuid)
    }

    fn get_latest_event(&self) -> Result<Option<EventId>, Error> {
        let from_sqlite_error =
            |err| Error::SqliteError(err, "Sqlite error when getting latest event".to_string());

        self.get_conn()
            .and_then(|conn| {
                conn.prepare(&format!(
                    "SELECT uuid FROM {} ORDER BY id DESC LIMIT 1",
                    &self.table
                ))?
                .query_row([], |row| row.get::<_, Uuid>("uuid"))
                .optional()
            })
            .map_err(from_sqlite_error)
    }

    fn read_events<'a>(
        &'a self,
        starting_from: Option<EventId>,
    ) -> Box<dyn Iterator<Item = Result<KnownEvent<Event>, Error>> + 'a> {
        let return_error = |wrapped_err| Box::new([Err(wrapped_err)].into_iter());

        let result = starting_from
            // Get the `id` we are starting from based on the `uuid`
            .map(|uuid| self.get_id_from_uuid(uuid))
            .transpose();

        let id = match result {
            Ok(id) => id,
            Err(err) => {
                return return_error(Error::SqliteError(
                    err,
                    String::from("Failed to get id from UUID"),
                ))
            }
        };

        let conn = match self.get_conn() {
            Ok(conn) => conn,
            Err(err) => {
                return return_error(Error::SqliteError(
                    err,
                    String::from("Failed to get Sqlite connection"),
                ))
            }
        };

        let statement = match starting_from {
            Some(_uuid) => conn.prepare(&format!(
                "SELECT id, uuid, payload FROM {} WHERE id >= ? ORDER BY id",
                &self.table
            )),
            None => conn.prepare(&format!("SELECT id, uuid, payload FROM {}", &self.table)),
        };

        let mut statement = match statement {
            Ok(stmt) => stmt,
            Err(err) => {
                return return_error(Error::SqliteError(
                    err,
                    String::from("Failed to prepare statement"),
                ))
            }
        };

        let query_result = match id {
            Some(id) => statement.query(params![id]),
            None => statement.query(params![]),
        };

        let rows = match query_result {
            Ok(rows) => rows,
            Err(err) => {
                return return_error(Error::SqliteError(err, String::from("Failed to get rows")))
            }
        };

        // Get the UUID and JSON
        let events: Vec<Result<KnownEvent<Event>, Error>> = rows
            .mapped(|row| {
                match (row.get::<_, Uuid>("uuid"), row.get::<_, String>("payload")) {
                    (Ok(uuid), Ok(json)) => Ok((uuid, json)),
                    (Ok(_uuid), Err(err)) => Err(err),
                    (Err(err), Ok(_uuid)) => Err(err),
                    // TODO: Do we want to somehow combine multiple errors?
                    (Err(err1), Err(_err2)) => Err(err1),
                }
            })
            // And deserialize it into a KnownEvent
            .map(|item_result| {
                item_result
                    .map_err(|err| {
                        Error::SqliteError(err, "Sqlite error during read_events".to_string())
                    })
                    .and_then(
                        |(uuid, json)| match serde_json::de::from_str::<Event>(&json) {
                            Ok(payload) => Ok(KnownEvent { uuid, payload }),
                            Err(err) => Err(Error::JsonSerialiseError(
                                err,
                                format!("Failed to deserialize payload for event with uuid={uuid}"),
                            )),
                        },
                    )
            })
            .collect();

        // Put the whole thing in an iterator box
        Box::new(events.into_iter())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rusqlite::Connection;
    use serde::{Deserialize, Serialize};
    use tempfile::tempdir;
    use uuid::Uuid;

    #[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
    struct TestEvent {
        data: String,
    }

    #[test]
    fn test_publish_and_read_events() {
        let dir = tempdir().unwrap();
        let file_path = dir.path().join("test.db");
        let file = file_path.to_str().unwrap();
        let table = "events";
        let store = SqliteEventStore::<TestEvent>::new(file, table).unwrap();

        let uuid = Uuid::new_v4();
        let event = TestEvent {
            data: "test".to_string(),
        };

        // Test publish method
        store.publish(uuid, event.clone()).unwrap();

        // Test read_events method
        let events = store
            .read_events(None)
            .collect::<Result<Vec<_>, _>>()
            .unwrap();
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].uuid, uuid);
        assert_eq!(events[0].payload, event);
    }

    // TEST read_events from certain offset

    #[test]
    fn test_get_latest_event() {
        let dir = tempdir().unwrap();
        let file_path = dir.path().join("test.db");
        let file = file_path.to_str().unwrap();
        let table = "events";
        let store = SqliteEventStore::<TestEvent>::new(file, table).unwrap();

        let uuid1 = Uuid::new_v4();
        let event1 = TestEvent {
            data: "test1".to_string(),
        };
        store.publish(uuid1, event1).unwrap();

        let uuid2 = Uuid::new_v4();
        let event2 = TestEvent {
            data: "test2".to_string(),
        };
        store.publish(uuid2, event2).unwrap();

        // Test get_latest_event method
        let latest_uuid = store
            .get_latest_event()
            .expect("get_latest_event_worked")
            .expect("event existed");
        assert_eq!(latest_uuid, uuid2);
    }

    #[test]
    fn test_get_latest_event_none() {
        let dir = tempdir().unwrap();
        let file_path = dir.path().join("test.db");
        let file = file_path.to_str().unwrap();
        let table = "events";
        let store = SqliteEventStore::<TestEvent>::new(file, table).unwrap();
        let latest_uuid = store.get_latest_event().expect("get_latest_event worked");
        assert!(
            latest_uuid.is_none(),
            "It should return None because no events exist yet"
        )
    }

    struct ColumnInfo {
        name: String,
        sql_type: String,
        not_null: bool,
        in_primary_key: bool,
    }

    #[test]
    fn test_table_creation() {
        let dir = tempdir().unwrap();
        let file_path = dir.path().join("test.db");
        let file = file_path.to_str().unwrap();
        let table = "events";

        // Test new method
        let _ = SqliteEventStore::<TestEvent>::new(file, table).unwrap();

        let conn = Connection::open(file).unwrap();
        let mut statement = conn
            .prepare(format!("PRAGMA table_info({})", table).as_str())
            .unwrap();
        let mut rows = statement
            .query_map((), |row| {
                Ok(ColumnInfo {
                    name: row.get("name").unwrap(),
                    sql_type: row.get("type").unwrap(),
                    not_null: row.get("notnull").unwrap(),
                    in_primary_key: row.get("pk").unwrap(),
                })
            })
            .unwrap();

        let first_column = rows
            .next()
            .expect("The first column exists")
            .expect("And it's valid");

        assert_eq!(first_column.name, "id", "First colum is called `id`");
        assert_eq!(first_column.sql_type, "INTEGER", "First colum is TEXT");
        assert_eq!(first_column.not_null, true, "First colum is not nullable");
        assert_eq!(
            first_column.in_primary_key, true,
            "First colum is the primary key"
        );

        let second_column = rows
            .next()
            .expect("The first column exists")
            .expect("And it's valid");

        assert_eq!(second_column.name, "uuid", "Second colum is called `id`");
        assert_eq!(second_column.sql_type, "BLOB", "Second colum is BLOB");
        assert_eq!(second_column.not_null, true, "Second colum is not nullable");
        assert_eq!(
            second_column.in_primary_key, false,
            "Second colum is not the primary key"
        );

        let third_column = rows
            .next()
            .expect("The first column exists")
            .expect("And it's valid");

        assert_eq!(third_column.name, "payload", "Third colum is called `id`");
        assert_eq!(third_column.sql_type, "TEXT", "Third colum is TEXT");
        assert_eq!(third_column.not_null, true, "Third colum is not nullable");
        assert_eq!(
            third_column.in_primary_key, false,
            "Third colum is not the primary key"
        );

        assert!(
            rows.next().is_none(),
            "There shouldn't be more than three columns"
        );

        ()
    }

    #[test]
    fn test_table_creation_doesnt_override() {
        let dir = tempdir().unwrap();
        let file_path = dir.path().join("test.db");
        let file = file_path.to_str().unwrap();
        let table = "events";
        let test_uuid = Uuid::new_v4();

        // Create one first
        let first_event_store = SqliteEventStore::<TestEvent>::new(file, table).unwrap();
        first_event_store
            .publish(
                test_uuid,
                TestEvent {
                    data: "Hello".to_string(),
                },
            )
            .expect("Publish should work");

        let uuid1 = first_event_store
            .get_latest_event()
            .expect("get_latest_worked()")
            .expect("Event exists");
        assert_eq!(uuid1, test_uuid, "The first event store has the right UUID");

        // When we start a second event store, it shouldn't overwrite the first table
        let second_event_store = SqliteEventStore::<TestEvent>::new(file, table).unwrap();
        let uuid2 = second_event_store
            .get_latest_event()
            .expect("get_latest_worked()")
            .expect("Event exists");
        assert_eq!(
            uuid2, test_uuid,
            "The second event store also has the right UUID"
        );
    }
}
