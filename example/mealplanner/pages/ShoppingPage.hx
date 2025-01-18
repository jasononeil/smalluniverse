package mealplanner.pages;

import smalluniverse.DOM;
import mealplanner.ui.Paragraph;
import mealplanner.App.appRouter;
import smalluniverse.DOM.section;
import smalluniverse.Hooks;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;
import mealplanner.ui.Button;

using tink.CoreApi;

typedef ShoppingParams = {
	showShoppingLinks:Bool
}

enum ShoppingAction {
	RefreshList;
	TickItem(name:String);
	UntickItem(name:String);
	ClearCompleted;
}

typedef ShoppingData = {
	list:Map<String, Array<IngredientToBuy>>,
	numberOfItemsWithoutShop:Int,
	numberOfItemsTotal:Int,
	numberOfItemsUnticked:Int,
	showShoppingLinks:Bool,
};

typedef IngredientToBuy = {
	ingredient:String,
	ticked:Bool,
	meals:Array<{name:String, id:String}>
}

class ShoppingPage implements Page<
	ShoppingAction
	,
	ShoppingParams
	,
	ShoppingData
	> {
	public var actionEncoder:IJsonEncoder<ShoppingAction> = new JsonEncoder<ShoppingAction>();
	public var dataEncoder:IJsonEncoder<ShoppingData> = new JsonEncoder<ShoppingData>();

	public function new() {}

	public function render(data:ShoppingData) {
		return Layout(SiteHeader('Shopping List'), renderLists(data), [
			onInit(initArgs -> {
				final interval = js.Browser.window.setInterval(() -> {
					initArgs.triggerAction(RefreshList);
				}, 3000);
				return Some(() -> {
					js.Browser.window.clearInterval(interval);
				});
			}),
			Key("shopping-list-page")
		]);
	}

	function renderLists(data:ShoppingData):Html<ShoppingAction> {
		final shopLists = [for (storeName =>
			itemsForStore in data.list) section(
			[],
			[ShoppingList(storeName, itemsForStore.map(i -> {
				ingredient: i.ingredient,
				ticked: i.ticked,
				info: i.meals.map(m -> m.name).join(", "),
				onTickedChange: ticked -> ticked ? TickItem(
					i.ingredient
				) : UntickItem(i.ingredient)
			}), data.showShoppingLinks)]
		)];
		final shoppingListCount = Paragraph(
			'${data.numberOfItemsUnticked} / ${data.numberOfItemsTotal} items remaining'
		);
		final alertItemsWithNoShop = (data.numberOfItemsWithoutShop > 0) ? Paragraph(
			element(
				"strong",
				[],
				'${data.numberOfItemsWithoutShop} items without a shop set. '
			)
		) : nothing();
		final alertItemsWithNoShop = Paragraph(alertItemsWithNoShop);
		final clearBtn = Button(
			Action(ClearCompleted),
			"Clear Completed Items"
		);
		final selectShopBtn = Button(
			Link(appRouter.uriForShopSelectorPage({})),
			'Select Shops for Items'
		);
		final showShoppingLinksBtn = Button(Link(appRouter.uriForShoppingPage({
			showShoppingLinks: true
		})), 'Click and collect');
		return [
			alertItemsWithNoShop,
			clearBtn,
			selectShopBtn,
			showShoppingLinksBtn,
			shoppingListCount,
			shopLists
		];
	}
}
