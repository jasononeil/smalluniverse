/// An EventSource is a "source of truth" service for a particular data domain.
///
/// When a page attempts to create an event, it goes to this service.
/// During `handleEvent` the service must record the event so that we can share it with other services.
/// Usually it is easiest to use an `EventStore` for this under the hood.
///
/// If you want to reject the event (because it has invalid data, or the user doesn't have permission to do it, etc), `handleEvent` should return a rejected promise.
///
/// Note: an EventSource could contain its own projection based on its own data, to allow it to perform validation logic while handling new events.
/// This is also known as a "Write Model".
pub trait EventSource<Event> {
    /// Handle a command - an attempt to create a new event, subject to validation logic, updating a write model if needed, and adding to the event log.
    /// If the event should be rejected, return an Error.
    /// If the event is created successfully, Return an `Ok` result containing the EventId.
    fn handle_command(event: Event) -> Result<EventId, Error>;

    /// Get the latest event ID, to compare against bookmarks in projections.
    fn get_latest_event() -> Result<Option<EventId>, Error>;

    /// Read pages of events.
    fn read_events(
        number_to_read: usize,
        starting_from: Option<EventId>,
    ) -> Result<Vec<KnownEvent<Event>>, Error>;
}
