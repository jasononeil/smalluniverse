package mealplanner.domains;

import smalluniverse.eventsources.JsonFileEventSource;
import smalluniverse.SmallUniverse;

using tink.CoreApi;
using Lambda;

enum ShoppingListEvent {
	AddItemToShoppingList(item:ShoppingListItem);
	AddMealToShoppingList(meal:ShoppingListForMeal);
	UpdateMealOnShoppingList(meal:ShoppingListForMeal);
	RemoveMealFromShoppingList(mealId:String);
	TickItem(itemName:String);
	UntickItem(itemName:String);
}

typedef ShoppingListModel = {
	items:Array<ShoppingListItem>
}

typedef ShoppingListItem = {
	itemName:String,
	shop:String,
	meals:Array<{mealId:String, mealName:String}>,
	ticked:Bool
}

typedef ShoppingListForMeal = {
	mealId:String,
	name:String,
	items:Array<{itemName:String}>
}

class ShoppingListEventSource extends JsonFileEventSource<
	ShoppingListEvent,
	ShoppingListModel
	> {
	public function new(
		eventStore:EventStore<ShoppingListEvent>,
		writeModelJsonFile:String
	) {
		super(
			eventStore,
			writeModelJsonFile,
			new JsonEncoder<ShoppingListModel>(),
			update
		);
	}

	public function getAllItems():Promise<Array<ShoppingListItem>> {
		return this.readModel().next(model -> model.items);
	}

	function update(
		model:ShoppingListModel,
		event:ShoppingListEvent
	):Promise<ShoppingListModel> {
		switch event {
			case AddItemToShoppingList(item):
				addItem(model, item);
			case AddMealToShoppingList(meal):
				addMealToShoppingList(model, meal);
			case UpdateMealOnShoppingList(meal):
				removeMealFromShoppingList(model, meal.mealId);
				addMealToShoppingList(model, meal);
			case RemoveMealFromShoppingList(mealId):
				removeMealFromShoppingList(model, mealId);
			case TickItem(itemName):
				for (item in model.items) {
					if (item.itemName == itemName) {
						item.ticked = true;
					}
				}
			case UntickItem(itemName):
				for (item in model.items) {
					if (item.itemName == itemName) {
						item.ticked = false;
					}
				}
		}
		return model;
	}

	function setMealOnItem(
		item:ShoppingListItem,
		mealId:String,
		mealName:String
	) {
		var existingMeal = item.meals.find(m -> m.mealId == mealId);
		if (existingMeal != null) {
			existingMeal.mealName = mealName;
		} else {
			item.meals.push({mealId: mealId, mealName: mealName});
		}
	}

	function addMealToShoppingList(
		model:ShoppingListModel,
		meal:ShoppingListForMeal
	) {
		for (item in meal.items) {
			var itemToAdd = model.items.find(i -> i.itemName == item.itemName);
			if (itemToAdd == null) {
				itemToAdd = {
					itemName: item.itemName,
					shop: Math.random() > 0.5 ? "Coles" : "Bulk",
					meals: [
						{
							mealId: meal.mealId,
							mealName: meal.name
						}
					],
					ticked: false
				}
			}
			setMealOnItem(itemToAdd, meal.mealId, meal.name);
			addItem(model, itemToAdd);
		}
	}

	function addItem(model:ShoppingListModel, item:ShoppingListItem) {
		final existing = model.items.find(i -> i.itemName == item.itemName);
		if (existing != null) {
			// Update shop, ticked, meals/
			existing.shop = item.shop;
			// Tick only if both the existing and the new are ticked.
			existing.ticked = item.ticked && existing.ticked;
			for (meal in item.meals) {
				final existingMeal = existing.meals.find(
					m -> meal.mealId == m.mealId
				);
				if (existingMeal != null) {
					existingMeal.mealName = meal.mealName;
				} else {
					existing.meals.push(meal);
				}
			}
		} else {
			model.items.push(item);
		}
	}

	function removeMealFromShoppingList(
		model:ShoppingListModel,
		mealId:String
	) {
		for (item in model.items) {
			for (meal in item.meals) {
				if (meal.mealId == mealId) {
					// Is removing an item while we're iterating okay?
					item.meals.remove(meal);
					if (item.meals.length == 0) {
						model.items.remove(item);
					}
				}
			}
		}
	}
}
