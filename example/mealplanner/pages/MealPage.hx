package mealplanner.pages;

import tink.core.Error;
import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.IngredientList;
import mealplanner.ui.ListView;
import mealplanner.App.getMockData;

using tink.CoreApi;
using Lambda;

final MealPage = Page(
	new MealView(),
	new MealApi(),
	new JsonEncoder<AppAction>(),
	new JsonEncoder<MealData>()
);

typedef MealParams = {
	mealId:String
}

typedef MealData = {
	mealId:String,
	mealName:String,
	ingredients:Ingredients
}

typedef Ingredients = Array<{ingredient:String, ticked:Bool, store:String}>;

class MealView implements PageView<AppAction, MealData> {
	public function new() {}

	public function render(data:MealData) {
		return Layout(SiteHeader(data.mealName), [
			IngredientList("Ingredients", data.ingredients.map(i -> {
				ingredient: i.ingredient,
				ticked: i.ticked,
				info: i.store
			}), ListItemInput("New Ingredient", "", _ -> Nothing))
		]);
	}
}

class MealApi implements PageApi<AppAction, MealParams, MealData> {
	public function new() {}

	public function getPageData(params:MealParams):Promise<MealData> {
		final mockData = getMockData();
		final meal = mockData.find(m -> m.id == params.mealId);
		if (meal == null) {
			throw new Error(NotFound, 'Could not find meal ${params.mealId}');
		}
		return {
			mealId: meal.id,
			mealName: meal.name,
			ingredients: meal.ingredients
		}
	}

	public function actionToCommand(params:MealParams, action:MealEvent) {
		// Our page actions happen to be the same as the meal events.
		return new Command(MealsEventSource, action);
	}
}
