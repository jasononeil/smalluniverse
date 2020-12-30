package mealplanner.pages;

import tink.core.Error;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;
import mealplanner.App.getMockData;

using Lambda;

final MealPage = Page(new MealView(), new MealApi());

typedef MealParams = {
	mealId:String
}

typedef MealData = {
	mealId:String,
	mealName:String,
	ingredients:Ingredients
}

typedef Ingredients = Array<{ingredient:String, ticked:Bool, store:String}>;

class MealView implements PageView<AppAction, MealData> {
	public function new() {}

	public function render(data:MealData) {
		return Layout(SiteHeader('Recipe for ${data.mealName}'), [IngredientList("Ingredients", data.ingredients)]);
	}
}

class MealApi implements PageApi<AppAction, MealParams, MealData> {
	public function new() {}

	public function getPageData(params:MealParams):MealData {
		final mockData = getMockData();
		final meal = mockData.find(m -> m.id == params.mealId);
		if (meal == null) {
			throw new Error(NotFound, 'Could not find meal ${params.mealId}');
		}
		return {mealId: meal.id, mealName: meal.name, ingredients: meal.ingredients}
	}

	public function pageDataShouldUpdate(params:MealParams, action:AppAction) {
		return false;
	}
}
