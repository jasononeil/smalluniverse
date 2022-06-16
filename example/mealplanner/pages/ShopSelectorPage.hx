package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.ShopSelector;

using tink.CoreApi;
using Lambda;

typedef ShopSelectorParams = {}

enum ShopSelectorAction {
	NewShop(name:String);
	SetShop(ingredient:String, shop:Null<String>);
}

typedef ShopSelectorData = {
	shops:Array<String>,
	itemsWithoutShop:Array<ItemToBuy>,
	itemsWithShop:Map<String, Array<ItemToBuy>>,
};

typedef ItemToBuy = {
	itemName:String,
	meals:Array<{name:String, id:String}>
}

class ShopSelectorPage implements Page<
	ShopSelectorAction,
	ShopSelectorParams,
	ShopSelectorData
	> {
	public var actionEncoder:IJsonEncoder<ShopSelectorAction> = new JsonEncoder<ShopSelectorAction>();
	public var dataEncoder:IJsonEncoder<ShopSelectorData> = new JsonEncoder<ShopSelectorData>();

	public function new() {}

	public function render(data:ShopSelectorData) {
		return Layout(
			SiteHeader('Select Shopping Lists'),
			renderShopSelector(data)
		);
	}

	function renderShopSelector(
		data:ShopSelectorData
	):Html<ShopSelectorAction> {
		return ShopSelector({
			shops: data.shops,
			onNewShop: shopName -> NewShop(shopName),
			itemsWithoutShop: data.itemsWithoutShop,
			itemsWithShop: data.itemsWithShop,
			onSetShop: (event) -> SetShop(event.itemName, event.shop.orNull()),
		});
	}
}
