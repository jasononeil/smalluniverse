use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub enum MealsEvent {
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
