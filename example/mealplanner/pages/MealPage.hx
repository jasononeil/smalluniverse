package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;
import mealplanner.ui.ListView;

using tink.CoreApi;

enum MealAction {
	AddIngredient(mealUrl:String, ingredient:String);
}

typedef MealParams = {
	mealId:String
}

typedef MealData = {
	mealId:String,
	mealName:String,
	ingredients:Ingredients
}

typedef Ingredients = Array<{ingredient:String, ticked:Bool, store:String}>;

class MealPage implements Page<MealAction, MealParams, MealData> {
	public var actionEncoder:IJsonEncoder<MealAction> = new JsonEncoder<MealAction>();
	public var dataEncoder:IJsonEncoder<MealData> = new JsonEncoder<MealData>();

	public function new() {}

	public function render(data:MealData) {
		return Layout(SiteHeader(data.mealName), [
			IngredientList("Ingredients", data.ingredients.map(i -> {
				ingredient: i.ingredient,
				ticked: i.ticked,
				info: i.store
			}), ListItemInput(
				"New Ingredient",
				"",
				text -> text != "" ? Some(
					AddIngredient(data.mealId, text)
				) : None
			))
		]);
	}
}
