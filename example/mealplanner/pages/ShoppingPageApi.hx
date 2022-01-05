package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.pages.ShoppingPage;

using tink.CoreApi;

class ShoppingPageApi implements PageApi<
	AppAction,
	ShoppingParams,
	ShoppingData
	> {
	public var relatedPage = ShoppingPage;

	public function new() {}

	public function getPageData(params:ShoppingParams):Promise<ShoppingData> {
		return {list: []};
		// final mockData = getMockData();
		// final allIngredients = [for (meal in mockData) for (ingredient in meal.ingredients) if (!ingredient.ticked) {
		// 	meal: meal,
		// 	ingredient: ingredient
		// }];
		// final stores = new Map<String, Array<IngredientToBuy>>();
		// for (i in allIngredients) {
		// 	var store = stores[i.ingredient.store];
		// 	if (store == null) {
		// 		store = [];
		// 		stores[i.ingredient.store] = store;
		// 	}
		// 	switch store.filter(
		// 		existingIngredient ->
		// 			i.ingredient.ingredient == existingIngredient.ingredient
		// 	)[
		// 		0
		// 		] {
		// 		case null:
		// 			store.push({
		// 				ingredient: i.ingredient.ingredient,
		// 				ticked: i.ingredient.ticked,
		// 				meals: [
		// 					i.meal
		// 				]
		// 			});
		// 		case existing:
		// 			// If it was previously ticked off, but this new meal has it unticked, untick on the list
		// 			if (!i.ingredient.ticked) {
		// 				existing.meals.push(i.meal);
		// 				existing.ticked = false;
		// 			}
		// 	}
		// }
		// final storesList = [for (store => list in stores) {
		// 	shopName: store,
		// 	list: list
		// }];
		// storesList.sort((s1, s2) -> s1.shopName > s2.shopName ? 1 : -1);
		// return {
		// 	list: storesList
		// };
	}

	public function actionToCommand(pageParams, action) {
		// TODO
		return Command.DoNothing;
	}
}
