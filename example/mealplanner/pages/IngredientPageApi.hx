package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.pages.IngredientPage;

using tink.CoreApi;
using Lambda;

class IngredientPageApi implements PageApi<
	AppAction,
	IngredientParams,
	IngredientData
	> {
	public var relatedPage = IngredientPage;

	public function new() {}

	public function getPageData(
		params:IngredientParams
	):Promise<IngredientData> {
		return {
			ingredient: params.ingredient,
			stores: new Map(),
			meals: []
		};
		// final mockData = getMockData();

		// final stores = new Map<String, Bool>();
		// for (meal in mockData) {
		// 	for (ingredient in meal.ingredients) {
		// 		if (ingredient.ingredient == params.ingredient) {
		// 			stores[ingredient.store] = true;
		// 		} else if (!stores.exists(ingredient.store)) {
		// 			stores[ingredient.store] = false;
		// 		}
		// 	}
		// }

		// final meals = mockData
		// 		.filter(
		// 		meal -> meal.ingredients.find(
		// 			(i) ->
		// 				i.ingredient == params.ingredient && !i.ticked) != null
		// 	)
		// 		.map(meal -> {
		// 		name: meal.name,
		// 		mealId: meal.id,
		// 	});

		// return {
		// 	ingredient: params.ingredient,
		// 	stores: stores,
		// 	meals: meals
		// }
	}

	public function actionToCommand(pageParams, action) {
		// TODO
		return Command.DoNothing;
	}
}
