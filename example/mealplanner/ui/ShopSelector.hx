package mealplanner.ui;

import js.html.SelectElement;
import mealplanner.ui.ListView;
import smalluniverse.DOM;
import smalluniverse.SmallUniverse.Html;
import mealplanner.ui.Heading;

using tink.CoreApi;
using Lambda;

typedef ShopSelectorProps<Action> = {
	shops:Array<String>,
	itemsWithoutShop:Array<{itemName:String, meals:Array<{name:String, id:String}>}>,
	itemsWithShop:Map<
		String,
		Array<{itemName:String, meals:Array<{name:String, id:String}>}>
		>,
	onNewShop:String->Action,
	onSetShop:({shop:Option<String>, itemName:String}) -> Action
}

/**
	Given a list of ingredients, show a select box for changing the shop you buy it from.
**/
function ShopSelector<Action>(props:ShopSelectorProps<Action>):Html<Action> {
	return [
		css(CompileTime.readFile("mealplanner/ui/ShopSelector.css")),

		if (props.itemsWithoutShop.length > 0) {
			[Heading3("Items Without Shop"), ListView([
				props.itemsWithoutShop.map(item -> ListItem([
					renderShopList(
						item.itemName,
						props.shops,
						None,
						(shop) -> props.onSetShop({
							itemName: item.itemName,
							shop: shop != "" ? Some(shop) : None
						})
					)
				]))
			])];
		} else {
			[];
		},

		[for (shopName => itemsForThisShop in props.itemsWithShop) [
			Heading3('Items from $shopName'),
			ListView([
				itemsForThisShop.map(item -> ListItem([
					renderShopList(
						item.itemName,
						props.shops,
						Some(shopName),
						(shop) -> props.onSetShop({
							itemName: item.itemName,
							shop: shop != "" ? Some(shop) : None
						})
					)
				]))
			]),
		]],

		Heading3("Shops"),
		ListView(props.shops.map(shopName -> ListItem(shopName)).concat([
			ListItemInput(
				"New Shop",
				"",
				shopName -> shopName != "" ? Some(
					props.onNewShop(shopName)
				) : None
			)
		])),

	];
}

function renderShopList<Action>(
	itemName:String,
	shops:Array<String>,
	currentShop:Option<String>,
	actionForShop:String->Action
):Html<Action> {
	final blank = option([
		attr("value", ""),
		booleanAttribute("selected", currentShop.match(None))
	], "");
	final shopsList = shops.map(shopName -> option([
		attr("value", shopName),
		booleanAttribute(
			"selected",
			currentShop.satisfies(value -> value == shopName)
		)
	], shopName));
	// TODO: use form onSubmit instead of select onChange
	return form([className("ShopSelector__form")], [itemName, select([
		name("shopName"),
		on("change", (event) -> {
			final select = cast(event.target, SelectElement);
			return Some(actionForShop(select.value));
		})
	], [blank, shopsList]), button([type("submit")], "Set")]);
}
