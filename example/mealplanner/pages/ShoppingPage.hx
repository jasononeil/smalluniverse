package mealplanner.pages;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

final ShoppingPage = Page(new ShoppingView(), new ShoppingApi());
typedef ShoppingParams = {}
typedef ShoppingData = {}

class ShoppingView implements PageView<AppAction, ShoppingData> {
	public function new() {}

	public function render(data:ShoppingData) {
		return h1([], [text("My shopping page!")]);
	}
}

class ShoppingApi implements PageApi<AppAction, ShoppingParams, ShoppingData> {
	public function new() {}

	public function getPageData(params:ShoppingParams) {
		return {}
	}

	public function pageDataShouldUpdate(params:ShoppingParams, action:AppAction) {
		return false;
	}
}
