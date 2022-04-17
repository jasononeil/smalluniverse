package mealplanner.pages;

import mealplanner.domains.ShoppingList.ShoppingListEventSource;
import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.domains.Meals;
import mealplanner.domains.ShoppingList;

using tink.CoreApi;
using Lambda;
using mealplanner.helpers.NullHelper;

class MealPageApi implements PageApi<MealAction, MealParams, MealData> {
	public var relatedPage = MealPage;

	var mealsModel:MealsEventSource;
	var shoppingListModel:ShoppingListEventSource;

	public function new(
		mealsModel:MealsEventSource,
		shoppingListModel:ShoppingListEventSource
	) {
		this.mealsModel = mealsModel;
		this.shoppingListModel = shoppingListModel;
	}

	public function getPageData(params:MealParams):Promise<MealData> {
		final mealPromise = mealsModel.getMeal(params.mealId);
		final shoppingListPromise = shoppingListModel.getItemsForMeal(
			params.mealId
		);
		final bothPromises = mealPromise && shoppingListPromise;
		return bothPromises.next(pair -> {
			final meal = pair.a;
			final shoppingList = pair.b;
			return {
				mealId: meal.slug,
				mealName: meal.name,
				ingredients: meal.ingredients.map(i -> {
					name: i.name,
					ticked: shoppingList
							.find(item -> item.itemName == i.name)
							.mapNonNullValue(item -> item.ticked)
							.or(true)
				})
			};
		});
	}

	public function actionToCommand(
		params:MealParams,
		action:MealAction
	):Promise<Command<Any>> {
		switch action {
			case AddIngredient(mealUrl, ingredient):
				return new Command(
					MealsEventSource,
					AddIngredient(mealUrl, ingredient)
				);
			case AddToShoppingList:
				return mealsModel
						.getMeal(params.mealId)
						.next(
						meal -> new Command(
							ShoppingListEventSource,
							AddMealToShoppingList({
								mealId: params.mealId,
								name: meal.name,
								items: meal.ingredients.map(i -> {
									itemName: i.name
								})
							})
						)
					);
			case TickIngredient(ingredient):
				return new Command(
					ShoppingListEventSource,
					RemoveItemFromShoppingList(ingredient, params.mealId)
				);
			case UntickIngredient(ingredient):
				return mealsModel
						.getMeal(params.mealId)
						.next(
						meal -> new Command(
							ShoppingListEventSource,
							AddItemToShoppingList({
								itemName: ingredient,
								shop: null,
								meals: [{
									mealId: params.mealId,
									mealName: meal.name
								}],
								ticked: false
							})
						)
					);
		}
	}
}
