package mealplanner.ui;

import smalluniverse.DOM;
import mealplanner.ui.ListView;

typedef TypeAheadListProps<ItemData, Action> = {
	label:String,
	input:String,
	items:Array<ItemData>,
	renderItemLabel:ItemData->String,
	onInput:String->Void,
	onClickExistingItem:ItemData->Action,
	onNewItem:String->Action,
}

function TypeAheadList<
	ItemData
	,
	Action
	>(props:TypeAheadListProps<ItemData, Action>) {
	return ListView([div([on("input", (e) -> {
		props.onInput(untyped e.target.value);
		return None;
	})], ListItemInput(
		props.label,
		"",
		itemName -> Some(props.onNewItem(itemName))
	))].concat(TypeAheadListItems(props)));
}

function TypeAheadListItems<
	ItemData
	,
	Action
	>(props:TypeAheadListProps<ItemData, Action>) {
	return props.items.map(
		item -> ListItemButton(
			props.renderItemLabel(item),
			props.onClickExistingItem(item)
		)
	);
}
