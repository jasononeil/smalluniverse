use super::EventStore;
use crate::types::{Error, EventId, KnownEvent};
use serde::{de::DeserializeOwned, Serialize};
use std::fmt::Debug;
use std::fs;
use std::io::{BufRead, BufReader, Error as IoError, Read, Seek, SeekFrom, Write};
use std::marker::PhantomData;
use std::path::Path;
use std::str::FromStr;
use uuid::Uuid;

/// A simple event store that stores events in "Tab Separated Value" (TSV) format in a local flat file.
///
/// Each row has the format:
///
/// {eventId}\t{eventJson}
///
/// This should probably not be used in production environments that expect significant traffic.
///
/// It is useful for easy-to-inspect local development.
/// Or more truthfully, for when I'm hacking on this project and don't want to introduce SQL just yet.

pub struct TSVEventStore<Event> {
    file: String,
    phantom: PhantomData<Event>,
}

impl<Event> TSVEventStore<Event> {
    pub fn new(file: &str) -> TSVEventStore<Event> {
        TSVEventStore::<Event> {
            file: file.to_string(),
            phantom: PhantomData,
        }
    }

    fn read_file(&self) -> Result<String, IoError> {
        fs::read_to_string(&self.file)
    }
}

impl<Event> EventStore<Event> for TSVEventStore<Event>
where
    Event: Serialize + DeserializeOwned + Debug,
{
    fn publish(&self, uuid: Uuid, event: Event) -> Result<EventId, Error> {
        let already_exists = Path::new(&self.file).exists();

        let mut file = fs::File::options()
            .read(true)
            .append(true)
            .create(true)
            .open(&self.file)
            .map_err(|err| Error::IoError(err, format!("Failed to open file {}", self.file)))?;

        let mut leading_newline_if_required = "";

        if already_exists {
            file.seek(SeekFrom::End(-1))
                .map_err(|err| Error::IoError(err, "Could not seek to last byte".to_string()))?;

            let mut last_byte = [0];

            file.read_exact(&mut last_byte)
                .map_err(|err| Error::IoError(err, "Could not read last byte".to_string()))?;

            let last_char = last_byte[0] as char;
            if last_char != '\n' {
                leading_newline_if_required = "\n";
            }
        }

        let json = serde_json::to_string(&event).map_err(|err| {
            Error::JsonSerialiseError(err, "Failed to serialize JSON".to_string())
        })?;
        file.write(format!("{leading_newline_if_required}{uuid}\t{json}\n").as_bytes())
            .map_err(|err| Error::IoError(err, "Failed to write to file".to_string()))?;
        Ok(uuid)
    }

    fn get_latest_event(&self) -> Result<Option<EventId>, Error> {
        let tsv_content = &self
            .read_file()
            .map_err(|err| Error::IoError(err, format!("Failed to read TSV file {}", self.file)))?;

        let final_line = tsv_content.lines().last();
        let final_line = match final_line {
            Some(final_line) => final_line,
            None => return Ok(None),
        };

        match final_line.split_once('\t') {
            Some((id, _json)) => match Uuid::from_str(id) {
                Ok(uuid) => Ok(Some(uuid)),
                Err(err) => Err(Error::UuidError(
                    err,
                    format!("Invalid UUID {} in final line of file {}", id, final_line),
                )),
            },
            None => Err(Error::MissingTabError(format!(
                "The latest line in {} did not contain a tab: \"{}\"",
                &self.file, final_line
            ))),
        }
    }

    fn read_events<'a>(
        &'a self,
        starting_from: Option<EventId>,
    ) -> Box<dyn Iterator<Item = Result<KnownEvent<Event>, Error>> + 'a> {
        let file = fs::File::open(&self.file);

        if let Err(err) = file {
            let error: Result<KnownEvent<Event>, Error> = Err(Error::IoError(
                err,
                format!("Failed to read file {}", &self.file),
            ));
            return Box::new([error].into_iter());
        }

        let iter = BufReader::new(file.unwrap())
            .lines()
            .filter_map(|line| match line {
                Ok(str) => {
                    if str.trim().is_empty() {
                        None
                    } else {
                        Some(Ok(str))
                    }
                }
                Err(err) => Some(Err(Error::IoError(
                    err,
                    format!("Failed to read lines from file {}", &self.file),
                ))),
            })
            .map(|line| match line {
                Ok(str) => str
                    .split_once('\t')
                    .map(|(id, json)| (id.to_owned(), json.to_owned()))
                    .ok_or(Error::MissingTabError(format!(
                        "In file {} line was missing tab: {}",
                        &self.file, str
                    ))),
                Err(err) => Err(err),
            })
            .map(|line| match line {
                Ok((id, json)) => match Uuid::from_str(&id) {
                    Ok(uuid) => Ok((uuid, json)),
                    Err(err) => Err(Error::UuidError(
                        err,
                        format!("Line had invalid UUID: {}", id),
                    )),
                },
                Err(err) => Err(err),
            })
            .skip_while(move |line| match starting_from {
                Some(starting_from_id) => match line {
                    Ok((uuid, _json)) => starting_from_id != *uuid,
                    // If we failed to read lines from the file, or this line did not have a tab separator,
                    // it almost certainly isn't the ID we're looking for, and is safe to skip
                    Err(_) => false,
                },
                // If starting_from is None, we don't skip any events.
                None => false,
            })
            .map(|line| match line {
                Ok((uuid, json)) => serde_json::de::from_str(&json)
                    .map(|payload| KnownEvent { uuid, payload })
                    .map_err(|serde_err| {
                        Error::JsonSerialiseError(
                            serde_err,
                            format!(
                                "Failed to decode JSON line in file {}: {}",
                                &self.file, json
                            ),
                        )
                    }),

                Err(err) => Err(err),
            })
            .into_iter();

        Box::new(iter)
    }
}

#[cfg(test)]
mod tests {
    use super::TSVEventStore;
    use crate::types::{Error, KnownEvent};
    use crate::EventStore;
    use serde::{Deserialize, Serialize};
    use std::error::Error as StdError;
    use std::fs;
    use std::io::Write;
    use tempfile::NamedTempFile;
    use uuid::Uuid;

    #[derive(Serialize, Deserialize, Debug, PartialEq)]
    enum TestEvent {
        EmptyEvent,
        SaidGreeting(String),
    }

    fn setup_test_tsv(
        tsv_content: String,
    ) -> Result<(NamedTempFile, TSVEventStore<TestEvent>), Error> {
        let mut temp_tsv = NamedTempFile::new().map_err(|err| {
            Error::IoError(
                err,
                String::from("Failed to create temporary TSV file for test"),
            )
        })?;

        temp_tsv
            .as_file_mut()
            .write(tsv_content.as_bytes())
            .map_err(|err| {
                Error::IoError(
                    err,
                    String::from("Failed to write to temporary TSV for test"),
                )
            })?;

        let tsv_store = TSVEventStore::<TestEvent>::new(
            temp_tsv
                .path()
                .to_str()
                .expect("Temp file path wasn't valid unicode"), // todo: return error rather than panic
        );

        Ok((temp_tsv, tsv_store))
    }

    #[test]
    fn publish_file_directory_does_not_exist() {
        let tsv_store = TSVEventStore::<TestEvent>::new("/path/that/does/not/exist");
        let result = tsv_store.publish(Uuid::new_v4(), TestEvent::EmptyEvent);

        assert!(result.is_err());
    }

    #[test]
    fn publish_file_new_file() -> Result<(), Box<dyn StdError>> {
        let temp_dir = tempfile::TempDir::new()?;
        let temp_dir = temp_dir
            .path()
            .to_str()
            .expect("Temp dir path was valid unicode");
        let temp_file = format!("{temp_dir}/file.tsv");
        let tsv_store = TSVEventStore::<TestEvent>::new(&temp_file);

        let event_id = Uuid::new_v4();

        tsv_store.publish(event_id, TestEvent::EmptyEvent)?;

        let content = std::fs::read_to_string(&temp_file)?;

        assert_eq!(content, format!("{}\t\"EmptyEvent\"\n", &event_id));

        Ok(())
    }

    #[test]
    fn publish_to_existing_file() -> Result<(), Box<dyn StdError>> {
        let tsv_content = String::from("0000\t\"EmptyEvent\"\n");
        let (tmp_file, tsv_store) = setup_test_tsv(tsv_content)?;

        let event_id = Uuid::new_v4();
        tsv_store.publish(event_id, TestEvent::EmptyEvent)?;

        let content = std::fs::read_to_string(&tmp_file.path())?;

        assert_eq!(
            content,
            format!("0000\t\"EmptyEvent\"\n{}\t\"EmptyEvent\"\n", &event_id)
        );

        Ok(())
    }

    #[test]
    fn publish_to_file_with_no_trailing_newline() -> Result<(), Box<dyn StdError>> {
        let tsv_content = String::from("0000\t\"EmptyEvent\"");
        let (tmp_file, tsv_store) = setup_test_tsv(tsv_content)?;

        let event_id = Uuid::new_v4();
        tsv_store.publish(event_id, TestEvent::EmptyEvent)?;

        let content = std::fs::read_to_string(&tmp_file.path())?;

        assert_eq!(
            content,
            format!("0000\t\"EmptyEvent\"\n{}\t\"EmptyEvent\"\n", &event_id)
        );

        Ok(())
    }

    #[test]
    fn get_latest_event_handles_io_errors() -> Result<(), Box<dyn StdError>> {
        let tsv_store = TSVEventStore::<TestEvent>::new("/path/that/does/not/exist");

        let result = tsv_store.get_latest_event();

        assert!(result.is_err());

        Ok(())
    }

    #[test]
    fn get_latest_event_on_empty_file() -> Result<(), Box<dyn StdError>> {
        let tsv_content = String::from("");
        let (_tmp_file, tsv_store) = setup_test_tsv(tsv_content)?;

        let result = tsv_store.get_latest_event()?;

        assert!(result.is_none());

        Ok(())
    }

    #[test]
    fn get_latest_event_invalid_file() -> Result<(), Box<dyn StdError>> {
        let tsv_content = String::from(
            "\
00001\t{}
00002\t{}
00003:{}",
        );
        let (_tmp_file, tsv_store) = setup_test_tsv(tsv_content)?;

        let result = tsv_store.get_latest_event();
        assert!(result.is_err());
        if let Err(err) = result {
            return match err {
                Error::MissingTabError(_) => Ok(()),
                _ => panic!("Should have been a missing tab error"),
            };
        }

        Ok(())
    }

    #[test]
    fn get_latest_event() -> Result<(), Box<dyn StdError>> {
        let tsv_content = String::from(
            "\
e2f71d24-0e36-49a5-9375-4294242580e9\t{}
6e6efb22-1cab-443d-8e6e-f091c7a7706f\t{}
00c9ceb7-37b2-49af-9e16-56eea69e5325\t{}",
        );
        let (_tmp_file, tsv_store) = setup_test_tsv(tsv_content)?;

        let latest_id = tsv_store.get_latest_event()?.unwrap();
        let expected_uuid = Uuid::parse_str("00c9ceb7-37b2-49af-9e16-56eea69e5325")?;

        assert_eq!(latest_id, expected_uuid);

        Ok(())
    }

    #[test]
    fn get_latest_event_trailing_newline() -> Result<(), Box<dyn StdError>> {
        let tsv_content = String::from(
            "\
e2f71d24-0e36-49a5-9375-4294242580e9\t{}
6e6efb22-1cab-443d-8e6e-f091c7a7706f\t{}
00c9ceb7-37b2-49af-9e16-56eea69e5325\t{}
",
        );
        let (_tmp_file, tsv_store) = setup_test_tsv(tsv_content)?;

        let latest_id = tsv_store.get_latest_event()?.unwrap();
        let expected_uuid = Uuid::parse_str("00c9ceb7-37b2-49af-9e16-56eea69e5325")?;

        assert_eq!(latest_id, expected_uuid);

        Ok(())
    }

    #[test]
    fn read_events_returns_iterator_over_events() {
        let temp_dir = tempfile::tempdir().unwrap();
        let file_path = temp_dir.path().join("test.tsv");
        let file_contents = "f7fa5475-620c-4021-941f-99b63a280b92\t{\"SaidGreeting\": \"Hello\"}\n\
                         5e63e1c8-7204-4f3b-a2b2-9c9f936294b1\t{\"SaidGreeting\": \"G'day\"}\n\
                         39d5c03b-b62f-4a20-a21a-347e1cc29c1b\t\"EmptyEvent\"\n";
        fs::write(&file_path, file_contents).unwrap();
        let event_store: TSVEventStore<TestEvent> = TSVEventStore::new(file_path.to_str().unwrap());

        let events: Vec<_> = event_store.read_events(None).map(|r| r.unwrap()).collect();

        let expected_events = vec![
            KnownEvent {
                uuid: Uuid::parse_str("f7fa5475-620c-4021-941f-99b63a280b92").unwrap(),
                payload: TestEvent::SaidGreeting("Hello".to_string()),
            },
            KnownEvent {
                uuid: Uuid::parse_str("5e63e1c8-7204-4f3b-a2b2-9c9f936294b1").unwrap(),
                payload: TestEvent::SaidGreeting("G'day".to_string()),
            },
            KnownEvent {
                uuid: Uuid::parse_str("39d5c03b-b62f-4a20-a21a-347e1cc29c1b").unwrap(),
                payload: TestEvent::EmptyEvent,
            },
        ];

        assert_eq!(events, expected_events);
    }

    #[test]
    fn read_events_returns_empty_iterator_for_empty_file() {
        let temp_dir = tempfile::tempdir().unwrap();
        let file_path = temp_dir.path().join("test.tsv");
        fs::write(&file_path, "").unwrap();
        let event_store: TSVEventStore<TestEvent> = TSVEventStore::new(file_path.to_str().unwrap());

        let events: Vec<_> = event_store.read_events(None).map(|r| r.unwrap()).collect();

        assert!(events.is_empty());
    }

    #[test]
    fn read_events_returns_iterator_starting_from_specified_id() {
        let temp_dir = tempfile::tempdir().unwrap();
        let file_path = temp_dir.path().join("test.tsv");
        let file_contents = "f7fa5475-620c-4021-941f-99b63a280b92\t{\"SaidGreeting\": \"Hello\"}\n\
5e63e1c8-7204-4f3b-a2b2-9c9f936294b1\t{\"SaidGreeting\": \"G'day\"}\n\
39d5c03b-b62f-4a20-a21a-347e1cc29c1b\t\"EmptyEvent\"\n
cbabcaae-5b9d-4a65-88d1-a71f184ca7b2\t{\"SaidGreeting\": \"Yo\"}\n";
        fs::write(&file_path, file_contents).unwrap();
        let event_store: TSVEventStore<TestEvent> = TSVEventStore::new(file_path.to_str().unwrap());

        let events: Vec<_> = event_store
            .read_events(Some(
                Uuid::parse_str("39d5c03b-b62f-4a20-a21a-347e1cc29c1b")
                    .expect("test uuid is valid"),
            ))
            .map(|r| r.unwrap())
            .collect();

        let expected_events = vec![
            KnownEvent {
                uuid: Uuid::parse_str("39d5c03b-b62f-4a20-a21a-347e1cc29c1b").unwrap(),
                payload: TestEvent::EmptyEvent,
            },
            KnownEvent {
                uuid: Uuid::parse_str("cbabcaae-5b9d-4a65-88d1-a71f184ca7b2").unwrap(),
                payload: TestEvent::SaidGreeting("Yo".to_string()),
            },
        ];

        assert_eq!(events, expected_events);
    }
}
