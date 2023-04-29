use serde::{Deserialize, Serialize};
use smalluniverse::types::KnownEvent;
use smalluniverse::{tsv_event_store::TSVEventStore, EventStore};

#[derive(Debug, Serialize, Deserialize)]
#[allow(non_snake_case)]
enum MealsEvent {
    NewMeal {
        name: String,
    },
    RenameMeal {
        oldId: String,
        newName: String,
    },
    DeleteMeal {
        mealId: String,
    },
    AddIngredient {
        meal: String,
        ingredient: String,
    },
    RenameIngredient {
        meal: String,
        oldIngredient: String,
        newIngredient: String,
    },
    DeleteIngredient {
        meal: String,
        ingredient: String,
    },
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let tsv_event_store = TSVEventStore::<MealsEvent>::new(
        "../example/app-content/prod/event-stores/events-meals.tsv",
    );

    let all_events = tsv_event_store.read_events(None);

    let mut events_read_successfully = 0;
    let mut error_count = 0;
    let mut last_event: Option<KnownEvent<MealsEvent>> = None;

    for event in all_events {
        match event {
            Ok(event) => {
                events_read_successfully += 1;
                last_event = Some(event);
            }
            Err(err) => {
                error_count += 1;
                println!("Failed to process event: {}", err);
            }
        }
    }

    println!(
        "Complete. {} errors. Read {} events. Last event {}",
        error_count,
        events_read_successfully,
        last_event.is_some()
    );

    Ok(())
}
