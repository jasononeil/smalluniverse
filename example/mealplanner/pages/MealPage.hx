package mealplanner.pages;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

final MealPage = Page(new MealView(), new MealApi());

typedef MealParams = {
	mealName:String
}

typedef MealData = {
	mealName:String
}

class MealView implements PageView<AppAction, MealData> {
	public function new() {}

	public function render(data:MealData) {
		return h1([], [text('Recipe for ${data.mealName}')]);
	}
}

class MealApi implements PageApi<AppAction, MealParams, MealData> {
	public function new() {}

	public function getPageData(params:MealParams):MealData {
		function capitalize(word:String)
			return word.charAt(0).toUpperCase() + word.substr(1);
		final mealName = params.mealName.split("-").map(capitalize).join(" ");
		return {mealName: mealName}
	}

	public function pageDataShouldUpdate(params:MealParams, action:AppAction) {
		return false;
	}
}
