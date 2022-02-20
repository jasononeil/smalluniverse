package mealplanner.pages;

import smalluniverse.DOM.nothing;
import smalluniverse.DOM.element;
import mealplanner.ui.Paragraph;
import mealplanner.App.appRouter;
import smalluniverse.DOM.href;
import smalluniverse.DOM.a;
import smalluniverse.DOM.section;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;

using tink.CoreApi;

typedef ShoppingParams = {}

enum ShoppingAction {
	TickItem(name:String);
	UntickItem(name:String);
}

typedef ShoppingData = {
	list:Map<String, Array<IngredientToBuy>>,
	numberOfItemsWithoutShop:Int,
};

typedef IngredientToBuy = {
	ingredient:String,
	ticked:Bool,
	meals:Array<{name:String, id:String}>
}

class ShoppingPage implements Page<
	ShoppingAction,
	ShoppingParams,
	ShoppingData
	> {
	public var actionEncoder:IJsonEncoder<ShoppingAction> = new JsonEncoder<ShoppingAction>();
	public var dataEncoder:IJsonEncoder<ShoppingData> = new JsonEncoder<ShoppingData>();

	public function new() {}

	public function render(data:ShoppingData) {
		return Layout(SiteHeader('Shopping List'), renderLists(data));
	}

	function renderLists(data:ShoppingData):Html<ShoppingAction> {
		final shopLists = [for (storeName =>
			itemsForStore in data.list) section(
			[],
			[IngredientList(storeName, itemsForStore.map(i -> {
				ingredient: i.ingredient,
				ticked: i.ticked,
				info: i.meals.map(m -> m.name).join(", "),
				onChange: ticked -> ticked ? TickItem(
					i.ingredient
				) : UntickItem(i.ingredient)
			}))]
		)];
		final alertItemsWithNoShop = (data.numberOfItemsWithoutShop > 0) ? element(
			"strong",
			[],
			'${data.numberOfItemsWithoutShop} items without a shop set. '
		) : nothing();
		final linkToSelectShop = Paragraph([alertItemsWithNoShop, a([
			href(appRouter.uriForShopSelectorPage({}))
		], 'Select Shops for Items.')]);
		return [linkToSelectShop, shopLists];
	}
}
