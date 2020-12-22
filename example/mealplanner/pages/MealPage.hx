package mealplanner.pages;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

final MealPage = Page(new MealView(), new MealApi());
typedef MealParams = {}
typedef MealData = {}

class MealView implements PageView<AppAction, MealData> {
	public function new() {}

	public function render(data:MealData) {
		return h1([], [text("My meal recipe!")]);
	}
}

class MealApi implements PageApi<AppAction, MealParams, MealData> {
	public function new() {}

	public function getPageData(params:MealParams) {
		return {}
	}

	public function pageDataShouldUpdate(params:MealParams, action:AppAction) {
		return false;
	}
}
