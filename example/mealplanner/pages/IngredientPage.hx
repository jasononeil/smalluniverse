package mealplanner.pages;

import mealplanner.App.appRouter;
import mealplanner.ui.Heading;
import mealplanner.ui.ListView;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.App.getMockData;

using Lambda;

final IngredientPage = Page(
	new IngredientView(),
	new IngredientApi(),
	new JsonEncoder<AppAction>(),
	new JsonEncoder<IngredientData>()
);

typedef IngredientParams = {
	ingredient:String
}

typedef IngredientData = {
	ingredient:String,
	stores:Map<String, Bool>,
	meals:Array<{mealId:String, name:String}>
}

class IngredientView implements PageView<AppAction, IngredientData> {
	public function new() {}

	public function render(data:IngredientData) {
		return Layout(SiteHeader('Ingredient: ${data.ingredient}'), [
			Heading3("Meals"),
			ListView([
				for (meal in data.meals)
					ListItemLink(meal.name, appRouter.uriForMealPage(meal))
			]),
			Heading3("Store"),
			ListView([
				for (store => selected in data.stores)
					ListItemCheckbox(store, selected, _ -> AppAction.Nothing)
			].concat([
				ListItemInput("Other store", "", _ -> AppAction.Nothing)
				]))
		]);
	}
}

class IngredientApi implements PageApi<
	AppAction,
	IngredientParams,
	IngredientData
	> {
	public function new() {}

	public function getPageData(params:IngredientParams):IngredientData {
		final mockData = getMockData();

		final stores = new Map<String, Bool>();
		for (meal in mockData) {
			for (ingredient in meal.ingredients) {
				if (ingredient.ingredient == params.ingredient) {
					stores[ingredient.store] = true;
				} else if (!stores.exists(ingredient.store)) {
					stores[ingredient.store] = false;
				}
			}
		}

		final meals = mockData
				.filter(
				meal -> meal.ingredients.find(
					(i) ->
						i.ingredient == params.ingredient && !i.ticked) != null
			)
				.map(meal -> {
				name: meal.name,
				mealId: meal.id,
			});

		return {
			ingredient: params.ingredient,
			stores: stores,
			meals: meals
		}
	}

	public function pageDataShouldUpdate(
		params:IngredientParams,
		action:AppAction
	) {
		return false;
	}
}
