pub mod event_store;
pub mod meal_planner;
pub mod types;

pub use event_store::tsv_event_store;
pub use event_store::EventStore;
pub use meal_planner::meals_event::MealsEvent;

pub fn run() -> Result<(), &'static str> {
    println!("Hello, world!");
    Ok(())
}
