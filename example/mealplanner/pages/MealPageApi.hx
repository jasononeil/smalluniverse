package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.domains.Meals;

using tink.CoreApi;
using Lambda;

class MealPageApi implements PageApi<MealAction, MealParams, MealData> {
	public var relatedPage = MealPage;

	var mealsModel:MealsEventSource;

	public function new(mealsModel:MealsEventSource) {
		this.mealsModel = mealsModel;
	}

	public function getPageData(params:MealParams):Promise<MealData> {
		return mealsModel.getMeal(params.mealId).next(meal -> {
			mealId: meal.slug,
			mealName: meal.name,
			ingredients: meal.ingredients
		});
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
