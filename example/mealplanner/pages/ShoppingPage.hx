package mealplanner.pages;

import smalluniverse.DOM.section;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;
import mealplanner.App.getMockData;

final ShoppingPage = Page(
	new ShoppingView(),
	new ShoppingApi(),
	new JsonEncoder<AppAction>(),
	new JsonEncoder<ShoppingData>()
);

typedef ShoppingParams = {}

typedef ShoppingData = {
	list:Array<{
		shopName:String,
		list:Array<IngredientToBuy>
	}>
}

typedef IngredientToBuy = {
	ingredient:String,
	ticked:Bool,
	meals:Array<{name:String, id:String}>
}

class ShoppingView implements PageView<AppAction, ShoppingData> {
	public function new() {}

	public function render(data:ShoppingData) {
		return Layout(SiteHeader('Shopping List'), renderLists(data));
	}

	function renderLists(data:ShoppingData):Html<AppAction> {
		return data.list.map(
			store -> section(
				[],
				IngredientList(store.shopName, store.list.map(i -> {
					ingredient: i.ingredient,
					ticked: i.ticked,
					info: i.meals.map(m -> m.name).join(", ")
				}))
			)
		);
	}
}

class ShoppingApi implements PageApi<AppAction, ShoppingParams, ShoppingData> {
	public function new() {}

	public function getPageData(params:ShoppingParams):ShoppingData {
		final mockData = getMockData();
		final allIngredients = [for (meal in mockData) for (ingredient in meal.ingredients) if (!ingredient.ticked) {
			meal: meal,
			ingredient: ingredient
		}];
		final stores = new Map<String, Array<IngredientToBuy>>();
		for (i in allIngredients) {
			var store = stores[i.ingredient.store];
			if (store == null) {
				store = [];
				stores[i.ingredient.store] = store;
			}
			switch store.filter(
				existingIngredient ->
					i.ingredient.ingredient == existingIngredient.ingredient
			)[
				0
				] {
				case null:
					store.push({
						ingredient: i.ingredient.ingredient,
						ticked: i.ingredient.ticked,
						meals: [
							i.meal
						]
					});
				case existing:
					// If it was previously ticked off, but this new meal has it unticked, untick on the list
					if (!i.ingredient.ticked) {
						existing.meals.push(i.meal);
						existing.ticked = false;
					}
			}
		}
		final storesList = [for (store => list in stores) {
			shopName: store,
			list: list
		}];
		storesList.sort((s1, s2) -> s1.shopName > s2.shopName ? 1 : -1);
		return {
			list: storesList
		};
	}

	public function pageDataShouldUpdate(
		params:ShoppingParams,
		action:AppAction
	) {
		return false;
	}
}
