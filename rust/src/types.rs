use std::fmt::Display;

use uuid::Uuid;

// ---------------------------------------------
// Notes:
// - I've made all the traits sync for now.
//   I'm still too new to Rust to know what to expect with async work,
//   I'd like to at least read https://rust-lang.github.io/async-book/
//   and understand the state of the ecosystem before choosing to make these async.
//   I wouldn't be surprised if I do though.
// ---------------------------------------------

#[derive(Debug)]
pub enum Error {
    IoError(std::io::Error, String),
    UuidError(uuid::Error, String),
    JsonSerialiseError(serde_json::Error, String),
    MissingTabError(String),
}

impl Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::IoError(inner, msg) => write!(f, "{msg}. ({inner})"),
            Self::JsonSerialiseError(inner, msg) => write!(f, "{msg}. ({inner})"),
            Self::UuidError(inner, msg) => write!(f, "{msg}. ({inner})"),
            Self::MissingTabError(msg) => write!(f, "{msg}"),
        }
    }
}

impl std::error::Error for Error {}

/// The Id for a particular event.
///
/// We are using UUIDs in our APIs here, so that they are a known size and rust can implement the `Copy` trait, which makes them easier to use than a String.
pub type EventId = Uuid;

/// An event that exists on a particular event stream.
///
/// This includes both the Event data (in `payload`) and the EventId for the stream it is in.
/// This type is used when fetching events in EventStores and EventSources.
#[allow(unused_must_use, dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub struct KnownEvent<Event> {
    pub uuid: EventId,
    pub payload: Event,
}
