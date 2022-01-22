package mealplanner.pages;

import smalluniverse.DOM.on;
import smalluniverse.DOM.button;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;
import mealplanner.ui.ListView;

using tink.CoreApi;

enum MealAction {
	AddIngredient(mealUrl:String, ingredient:String);
	AddToShoppingList;
	TickIngredient(ingredient:String);
	UntickIngredient(ingredient:String);
}

typedef MealParams = {
	mealId:String
}

typedef MealData = {
	mealId:String,
	mealName:String,
	ingredients:Ingredients
}

typedef Ingredients = Array<{name:String}>;

class MealPage implements Page<MealAction, MealParams, MealData> {
	public var actionEncoder:IJsonEncoder<MealAction> = new JsonEncoder<MealAction>();
	public var dataEncoder:IJsonEncoder<MealData> = new JsonEncoder<MealData>();

	public function new() {}

	public function render(data:MealData) {
		return Layout(SiteHeader(data.mealName), [button([
			on("click", (e) -> Some(AddToShoppingList))
		], [
			"Add to shopping list"
		]), IngredientList("Ingredients", data.ingredients.map(i -> {
			ingredient: i.name,
			ticked: true, // TODO: include in the page data
			info: null, // TODO: i.store
			onChange: (
				ticked
			) -> ticked ? TickIngredient(i.name) : UntickIngredient(i.name)
		}), ListItemInput(
			"New Ingredient",
			"",
			text -> text != "" ? Some(AddIngredient(data.mealId, text)) : None
		))]);
	}
}
