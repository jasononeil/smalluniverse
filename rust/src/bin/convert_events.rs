use smalluniverse::meal_planner::meals_event::MealsEvent;
use smalluniverse::sqlite_event_store::SqliteEventStore;
use smalluniverse::tsv_event_store::TSVEventStore;
use smalluniverse::EventStore;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let tsv_event_store = TSVEventStore::<MealsEvent>::new(
        "../example/app-content/prod/event-stores/events-meals.tsv",
    );
    let sqlite_event_store = SqliteEventStore::<MealsEvent>::new(
        "../example/app-content/prod/event-stores/events.sqlite",
        "MealEvents",
    )?;

    let latest_event = sqlite_event_store.get_latest_event()?;
    let all_events = tsv_event_store
        .read_events(latest_event)
        .skip(if latest_event.is_some() { 1 } else { 0 });
    let mut num_events_written = 0;

    for known_event in all_events {
        let known_event = known_event?;
        println!(
            "Writing event {}: {:?}",
            known_event.uuid, known_event.payload
        );
        sqlite_event_store.publish(known_event.uuid, known_event.payload)?;
        num_events_written += 1;
    }

    println!("Completed. {} events written.", num_events_written);

    Ok(())
}
