package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;

final ShoppingPage = Page(new ShoppingView(), new ShoppingApi());
typedef ShoppingParams = {}
typedef ShoppingData = {}

class ShoppingView implements PageView<AppAction, ShoppingData> {
	public function new() {}

	public function render(data:ShoppingData) {
		return Layout(SiteHeader('Shopping List'), ["my shopping list"]);
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
