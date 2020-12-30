package mealplanner.pages;

import smalluniverse.DOM.section;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;
import mealplanner.App.getMockData;

final ShoppingPage = Page(new ShoppingView(), new ShoppingApi());
typedef ShoppingParams = {}

typedef ShoppingData = {
	list:Array<{
		shopName:String,
		list:Array<{ingredient:String, ticked:Bool}>
	}>
}

class ShoppingView implements PageView<AppAction, ShoppingData> {
	public function new() {}

	public function render(data:ShoppingData) {
		return Layout(SiteHeader('Shopping List'), renderLists(data));
	}

	function renderLists(data:ShoppingData):Html<AppAction> {
		return data.list.map(store -> section([], IngredientList(store.shopName, store.list)));
	}
}

class ShoppingApi implements PageApi<AppAction, ShoppingParams, ShoppingData> {
	public function new() {}

	public function getPageData(params:ShoppingParams):ShoppingData {
		final mockData = getMockData();
		final allIngredients = [
			for (meal in mockData)
				for (ingredient in meal.ingredients)
					if (!ingredient.ticked)
						ingredient
		];
		final stores = new Map();
		for (ingredient in allIngredients) {
			var store = stores[ingredient.store];
			if (store == null) {
				store = [];
				stores[ingredient.store] = store;
			}
			store.push(ingredient);
		}
		final storesList = [for (store => list in stores) {shopName: store, list: list}];
		storesList.sort((s1, s2) -> s1.shopName > s2.shopName ? 1 : -1);
		return {
			list: storesList
		};
	}

	public function pageDataShouldUpdate(params:ShoppingParams, action:AppAction) {
		return false;
	}
}
