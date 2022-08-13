package mealplanner.pages;

import js.Browser.window;
import mealplanner.ui.ActionMenu;
import mealplanner.ui.Button;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;

using tink.CoreApi;

enum MealAction {
	AddIngredient(mealUrl:String, ingredient:String);
	AddToShoppingList;
	TickIngredient(ingredient:String);
	UntickIngredient(ingredient:String);
	EditIngredientName(oldName:String, newName:String);
	DeleteIngredient(ingredient:String);
	RenameMeal(newName:String);
	DeleteMeal;
}

typedef MealParams = {
	mealId:String
}

typedef MealData = {
	mealId:String,
	mealName:String,
	ingredients:Ingredients
}

typedef Ingredients = Array<{name:String, ticked:Bool}>;

class MealPage implements Page<MealAction, MealParams, MealData> {
	public var actionEncoder:IJsonEncoder<MealAction> = new JsonEncoder<MealAction>();
	public var dataEncoder:IJsonEncoder<MealData> = new JsonEncoder<MealData>();

	public function new() {}

	public function render(data:MealData) {
		return Layout(SiteHeader(data.mealName), [
			Button(Action(AddToShoppingList), "Untick all"),
			MealActions(data.mealName),
			MealItemList("Ingredients", data.ingredients.map(i -> {
				ingredient: i.name,
				ticked: i.ticked,
				onTickedChange: (
					ticked
				) -> ticked ? TickIngredient(i.name) : UntickIngredient(i.name),
				onEditName: newName -> EditIngredientName(i.name, newName),
				onDelete: DeleteIngredient(i.name),
			}), newItem -> AddIngredient(data.mealId, newItem))
		]);
	}
}

function MealActions(currentMealName:String) {
	return ActionMenu("⋯", ["Rename Meal" => () -> {
		final newName = window.prompt('New meal name', currentMealName);
		if (newName == null || newName == "") {
			return None;
		}
		Some(RenameMeal(newName));
	}, "Delete Meal" => () -> window.confirm(
		'Are you sure you want to delete the meal $currentMealName?'
	) ? Some(DeleteMeal) : None]);
}
