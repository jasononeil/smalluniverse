package mealplanner.pages;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

final HomePage = Page(new HomeView(), new HomeApi());
typedef HomeParams = {}
typedef HomeData = {}

class HomeView implements PageView<AppAction, HomeData> {
	public function new() {}

	public function render(data:HomeData):Html<AppAction> {
		return h1([], [text("My home page!")]);
	}
}

class HomeApi implements PageApi<AppAction, HomeParams, HomeData> {
	public function new() {}

	public function getPageData(params:HomeParams) {
		return {}
	}

	public function pageDataShouldUpdate(params:HomeParams, action:AppAction) {
		return false;
	}
}
