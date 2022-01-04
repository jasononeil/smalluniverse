package mealplanner.pages;

import smalluniverse.DOM.section;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;

using tink.CoreApi;

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

class ShoppingPage implements Page<AppAction, ShoppingParams, ShoppingData> {
	public var actionEncoder:IJsonEncoder<AppAction> = new JsonEncoder<AppAction>();
	public var dataEncoder:IJsonEncoder<ShoppingData> = new JsonEncoder<ShoppingData>();

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
