package mealplanner.pages;

import mealplanner.App.appRouter;
import smalluniverse.SmallUniverse;
import mealplanner.pages.QuickAddPage;
import mealplanner.domains.Meals;
import mealplanner.domains.ShoppingList;

using tink.CoreApi;
using Lambda;
using mealplanner.helpers.NullHelper;
using StringTools;

class QuickAddPageApi implements PageApi<
	QuickAddAction
	,
	QuickAddParams
	,
	QuickAddData
	> {
	public var relatedPage = QuickAddPage;

	var mealsModel:MealsEventSource;
	var shoppingListModel:ShoppingListEventSource;

	public function new(
		mealsModel:MealsEventSource,
		shoppingListModel:ShoppingListEventSource
	) {
		this.mealsModel = mealsModel;
		this.shoppingListModel = shoppingListModel;
	}

	public function getPageData(params:QuickAddParams):Promise<QuickAddData> {
		return mealsModel.getAllIngredients().next(ingredients -> {
			input: params.input,
			existingItems: ingredients.map(ingredient -> {
				itemName: ingredient.name,
				list: {
					listId: ingredient.meal.id,
					listName: ingredient.meal.name
				}
			}).filter(
				item -> item.itemName
						.toLowerCase()
						.contains(params.input.toLowerCase())
			)
		});
	}

	public function actionToCommand(
		params:QuickAddParams,
		action:QuickAddAction
	):Promise<Command<Any>> {
		switch action {
			case AddItem(itemName, list):
				return new Command(
					ShoppingListEventSource,
					AddItemToShoppingList({
						itemName: itemName,
						ticked: false,
						shop: null,
						meals: switch list {
							case Some(l): [
									{mealId: l.listId, mealName: l.listName}
								];
							default: [];
						}
					})
				).redirectIfSuccessful(appRouter.uriForQuickAdd({input: ""}));
		}
	}
}
