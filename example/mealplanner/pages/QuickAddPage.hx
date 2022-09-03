package mealplanner.pages;

import mealplanner.App.appRouter;
import smalluniverse.clients.Browser.triggerReplaceState;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.TypeAheadList;

using tink.CoreApi;

enum QuickAddAction {
	AddItem(itemName:String, list:Option<{listId:String, listName:String}>);
}

typedef QuickAddParams = {
	input:String
}

typedef QuickAddData = {
	input:String,
	existingItems:Array<Item>
}

typedef Item = {
	itemName:String,
	list:{listId:String, listName:String}
}

class QuickAddPage implements Page<
	QuickAddAction
	,
	QuickAddParams
	,
	QuickAddData
	> {
	public var actionEncoder:IJsonEncoder<QuickAddAction> = new JsonEncoder<QuickAddAction>();
	public var dataEncoder:IJsonEncoder<QuickAddData> = new JsonEncoder<QuickAddData>();

	public function new() {}

	public function render(data:QuickAddData) {
		return Layout(SiteHeader("Quick Add"), TypeAheadList({
			label: "Add an item",
			renderItemLabel: (
				item:Item
			) -> '➡️ ${item.itemName} (${item.list.listName})',
			items: data.existingItems,
			input: data.input,
			onInput: input -> triggerReplaceState(appRouter.uriForQuickAdd({
				input: input
			})),
			onNewItem: itemName -> AddItem(itemName, None),
			onClickExistingItem: (
				item:Item
			) -> AddItem(item.itemName, Some(item.list))
		}));
	}
}
