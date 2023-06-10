use super::EventStore;
use crate::types::{Error, EventId, KnownEvent};
use rusqlite::{params, Connection, Error as SqliteError, OptionalExtension};
use serde::{de::DeserializeOwned, Serialize};
use std::fmt::Debug;
use std::marker::PhantomData;
use std::str::FromStr;
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
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT UNIQUE NOT NULL,
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
                    params![uuid.to_string(), json],
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
                .query_row([], |row| row.get::<_, String>("uuid"))
                .optional()
            })
            .map_err(from_sqlite_error)
            .and_then(|option| match option {
                Some(str) => match Uuid::from_str(&str) {
                    Ok(uuid) => Ok(Some(uuid)),
                    Err(err) => Err(Error::UuidError(
                        err,
                        String::from("Failed to parse UUID in get_latest_event"),
                    )),
                },
                None => Ok(None),
            })
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
