package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealsListPage;
import mealplanner.domains.Meals;

using tink.CoreApi;

class MealsListPageApi implements PageApi<
	MealsListAction,
	MealsListParams,
	MealsListData
	> {
	public var relatedPage = MealsListPage;

	var mealsModel:MealsEventSource;

	public function new(mealsModel:MealsEventSource) {
		this.mealsModel = mealsModel;
	}

	public function getPageData(params:MealsListParams):Promise<MealsListData> {
		return mealsModel.getMealsList().next(meals -> {
			return {
				meals: meals.map(m -> {
					name: m.name,
					id: m.slug
				})
			};
		});
	}

	public function actionToCommand(
		params:MealsListParams,
		action:MealsListAction
	) {
		switch action {
			case NewMeal(name):
				return new Command(MealsEventSource, NewMeal(name));
		}
	}
}
