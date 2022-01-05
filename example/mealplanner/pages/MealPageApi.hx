package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.domains.Meals;

using tink.CoreApi;
using Lambda;

class MealPageApi implements PageApi<MealAction, MealParams, MealData> {
	public var relatedPage = MealPage;

	public function new() {}

	public function getPageData(params:MealParams):Promise<MealData> {
		return {
			mealId: params.mealId,
			mealName: params.mealId.toUpperCase(),
			ingredients: []
		};
		// final mockData = getMockData();
		// final meal = mockData.find(m -> m.id == params.mealId);
		// if (meal == null) {
		// 	throw new Error(NotFound, 'Could not find meal ${params.mealId}');
		// }
		// return {
		// 	mealId: meal.id,
		// 	mealName: meal.name,
		// 	ingredients: meal.ingredients
		// }
	}

	public function actionToCommand(params:MealParams, action:MealAction) {
		switch action {
			case AddIngredient(mealUrl, ingredient):
				return new Command(
					MealsEventSource,
					AddIngredient(mealUrl, ingredient)
				);
		}
	}
}
