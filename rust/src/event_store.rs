use uuid::Uuid;

use super::types::{Error, EventId, KnownEvent};

pub mod sqlite_event_store;
pub mod tsv_event_store;

/// An EventStore is for storing a stream of Events and recalling them in batches.
///
/// The storage mechanism could be in-memory, a flat file, a database, a Kafka stream, or almost anything.
pub trait EventStore<Event> {
    /// Publish the event to this EventStore.
    // It might be nice to track the event origin (eg Page(page,params,action) or Cli(command) or something...).
    fn publish(&self, event_id: Uuid, event: Event) -> Result<EventId, Error>;

    /// Get the ID of the latest event, or "None" if there is no events.
    fn get_latest_event(&self) -> Result<Option<EventId>, Error>;

    /// Read a number of events from a given starting point.
    /// If `starting_from` is None, then it will read from the beginning of the event stream.
    /// This returns a lazy iterator, so you can read as many or as few items as you want by using `Iterator.take()`
    fn read_events<'a>(
        &'a self,
        starting_from: Option<EventId>,
    ) -> Box<dyn Iterator<Item = Result<KnownEvent<Event>, Error>> + 'a>;
}
