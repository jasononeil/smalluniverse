package mealplanner.pages;

import mealplanner.domains.ShoppingList;
import smalluniverse.SmallUniverse;
import mealplanner.pages.ShopSelectorPage;

using tink.CoreApi;
using mealplanner.helpers.NullHelper;

class ShopSelectorPageApi implements PageApi<
	ShopSelectorAction,
	ShopSelectorParams,
	ShopSelectorData
	> {
	public var relatedPage = ShopSelectorPage;

	var shoppingListEventSource:ShoppingListEventSource;

	public function new(shoppingListEventSource:ShoppingListEventSource) {
		this.shoppingListEventSource = shoppingListEventSource;
	}

	public function getPageData(
		params:ShopSelectorParams
	):Promise<ShopSelectorData> {
		final bothPromises =
			shoppingListEventSource.getAllItems() &&
			shoppingListEventSource.getShops();
		return bothPromises.next(pair -> {
			final items = pair.a;
			final shops = pair.b;
			final itemsWithoutShop = [];
			final itemsWithShop:Map<String, Array<ItemToBuy>> = [];
			for (i in items) {
				final shopList = switch i.shop {
					case null:
						itemsWithoutShop;
					case shopName:
						itemsWithShop[shopName].orGet(() -> itemsWithShop[
							shopName
						] = []);
				}

				shopList.push({
					itemName: i.itemName,
					meals: i.meals.map(m -> {name: m.mealName, id: m.mealId}),
				});
			}
			return {
				itemsWithoutShop: itemsWithoutShop,
				itemsWithShop: itemsWithShop,
				shops: shops,
			};
		});
	}

	public function actionToCommand(pageParams, action):Promise<Command<Any>> {
		switch action {
			case NewShop(name):
				return new Command(ShoppingListEventSource, AddShop(name));
			case SetShop(ingredient, shop):
				return new Command(
					ShoppingListEventSource,
					SetShop(ingredient, shop != null ? Some(shop) : None)
				);
		}
	}
}
