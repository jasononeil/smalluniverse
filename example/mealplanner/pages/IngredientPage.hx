package mealplanner.pages;

import mealplanner.App.appRouter;
import mealplanner.ui.Heading;
import mealplanner.ui.ListView;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;

using tink.CoreApi;
using Lambda;

typedef IngredientParams = {
	ingredient:String
}

typedef IngredientData = {
	ingredient:String,
	stores:Map<String, Bool>,
	meals:Array<{mealId:String, name:String}>
}

class IngredientPage implements Page<
	AppAction,
	IngredientParams,
	IngredientData
	> {
	public var actionEncoder:IJsonEncoder<AppAction> = new JsonEncoder<AppAction>();
	public var dataEncoder:IJsonEncoder<IngredientData> = new JsonEncoder<IngredientData>();

	public function new() {}

	public function render(data:IngredientData) {
		return Layout(SiteHeader('Ingredient: ${data.ingredient}'), [
			Heading3("Meals"),
			ListView([
				for (meal in data.meals)
					ListItemLink(meal.name, appRouter.uriForMealPage(meal))
			]),
			Heading3("Store"),
			ListView([
				for (store => selected in data.stores)
					ListItemCheckbox(store, selected, _ -> AppAction.Nothing)
			].concat([
				ListItemInput("Other store", "", _ -> None)
				]))
		]);
	}
}
