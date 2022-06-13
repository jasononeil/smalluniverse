package mealplanner.domains;

import smalluniverse.eventsources.JsonFileEventSource;
import smalluniverse.SmallUniverse;

using tink.CoreApi;
using Lambda;

enum ShoppingListEvent {
	AddItemToShoppingList(item:ShoppingListItem);
	RemoveItemFromShoppingList(itemName:String, mealId:Null<String>);
	AddMealToShoppingList(meal:ShoppingListForMeal);
	UpdateMealOnShoppingList(meal:ShoppingListForMeal);
	RemoveMealFromShoppingList(mealId:String);
	TickItem(itemName:String);
	UntickItem(itemName:String);
	ClearCompleted;
	AddShop(shopName:String);
	SetShop(itemName:String, shopName:CopyOfOption<String>);
}

// Workaround for tink_json roundtrip issue with Option - https://github.com/haxetink/tink_json/issues/94
enum CopyOfOption<T> {
	Some(v:T);
	None;
}

typedef ShoppingListModel = {
	items:Array<ShoppingListItem>,
	shops:Array<String>,
	shopsForItems:Map<String, String>
}

typedef ShoppingListItem = {
	itemName:String,
	shop:Null<String>,
	meals:Array<{mealId:String, mealName:String}>,
	ticked:Bool
}

typedef ShoppingListForMeal = {
	mealId:String,
	name:String,
	items:Array<{itemName:String}>
}

class ShoppingListEventSource extends JsonFileEventSource<
	ShoppingListEvent
	,
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

	/** Return all items in the shipping list. **/
	public function getAllItems():Promise<Array<ShoppingListItem>> {
		return this.readModel().next(model -> model.items);
	}

	/** Return the items on the shopping list that are for a specific meal. **/
	public function getItemsForMeal(
		mealId:String
	):Promise<Array<ShoppingListItem>> {
		return this
				.readModel()
				.next(
				model -> model.items.filter(
					item -> item.meals.find(m -> m.mealId == mealId) != null
				)
			);
	}

	/** Return the list of shops we have to chose from. **/
	public function getShops():Promise<Array<String>> {
		return this.readModel().next(model -> model.shops);
	}

	function update(
		model:ShoppingListModel,
		event:ShoppingListEvent
	):Promise<ShoppingListModel> {
		switch event {
			case AddItemToShoppingList(item):
				addOrUpdateItem(model, item);
			case RemoveItemFromShoppingList(itemName, mealId):
				removeItem(model, itemName, mealId);
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
			case ClearCompleted:
				clearCompleted(model);
			case AddShop(shopName):
				model.shops.push(shopName);
			case SetShop(itemName, shopName):
				for (item in model.items) {
					if (item.itemName == itemName) {
						item.shop = switch shopName {
							case Some(v): v;
							case None: null;
						};
					}
				}
				switch shopName {
					case Some(shop):
						model.shopsForItems.set(itemName, shop);
					case None:
						model.shopsForItems.remove(itemName);
				}
		}
		return model;
	}

	function addMealToShoppingList(
		model:ShoppingListModel,
		meal:ShoppingListForMeal
	) {
		for (item in meal.items) {
			final itemToAdd = {
				itemName: item.itemName,
				shop: null,
				meals: [{
					mealId: meal.mealId,
					mealName: meal.name
				}],
				ticked: false
			};
			addOrUpdateItem(model, itemToAdd);
		}
	}

	function addOrUpdateItem(model:ShoppingListModel, item:ShoppingListItem) {
		if (item.shop == null && model.shopsForItems.exists(item.itemName)) {
			item.shop = model.shopsForItems.get(item.itemName);
		}
		final existing = model.items.find(i -> i.itemName == item.itemName);
		if (existing != null) {
			// Merge "shop", "ticked" and "meals" fields with existing item in a sensible way.
			existing.shop = item.shop != null ? item.shop : existing.shop;
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

	function removeItem(
		model:ShoppingListModel,
		itemName:String,
		mealId:Null<String>
	) {
		for (item in model.items) {
			if (item.itemName == itemName) {
				if (mealId != null) {
					item.meals = item.meals.filter(m -> m.mealId != mealId);
				} else {
					// Emptying it of meals will mean it is removed in the next step.
					// (Calling `model.items.remove(item)` now will mess up the for loop iterator).
					item.meals = [];
				}
			}
		}
		cleanUpItemsNotInAnyMeals(model);
	}

	function removeMealFromShoppingList(
		model:ShoppingListModel,
		mealId:String
	) {
		for (item in model.items) {
			item.meals = item.meals.filter(meal -> meal.mealId != mealId);
		}
		cleanUpItemsNotInAnyMeals(model);
	}

	function clearCompleted(model:ShoppingListModel) {
		model.items = model.items.filter(i -> i.ticked == false);
	}

	/**
		Currently our assumption is that shopping list items can be present for multiple "meals".
		If an item isn't for any meals, it shouldn't be on the list.
	**/
	function cleanUpItemsNotInAnyMeals(model:ShoppingListModel) {
		model.items = model.items.filter(i -> i.meals.length > 0);
	}
}
