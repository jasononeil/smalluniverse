package mealplanner.pages;

import mealplanner.domains.ShoppingList;
import smalluniverse.SmallUniverse;
import mealplanner.pages.ShoppingPage;

using tink.CoreApi;
using mealplanner.helpers.NullHelper;

class ShoppingPageApi implements PageApi<
	ShoppingAction,
	ShoppingParams,
	ShoppingData
	> {
	public var relatedPage = ShoppingPage;

	var shoppingListEventSource:ShoppingListEventSource;

	public function new(shoppingListEventSource:ShoppingListEventSource) {
		this.shoppingListEventSource = shoppingListEventSource;
	}

	public function getPageData(params:ShoppingParams):Promise<ShoppingData> {
		return shoppingListEventSource
				.getAllItems()
				.next(function(items):ShoppingData {
				final list = new Map<String, Array<IngredientToBuy>>();
				for (i in items) {
					final shopList = list[i.shop].orGet(
						() -> list[i.shop] = []
					);
					shopList.push({
						ingredient: i.itemName,
						meals: i.meals.map(
							m -> {name: m.mealName, id: m.mealId}
						),
						ticked: i.ticked
					});
				}
				return {
					list: list
				};
			});
	}

	public function actionToCommand(pageParams, action):Promise<Command<Any>> {
		switch action {
			case TickItem(name):
				return new Command(ShoppingListEventSource, TickItem(name));
			case UntickItem(name):
				return new Command(ShoppingListEventSource, UntickItem(name));
		}
	}
}
