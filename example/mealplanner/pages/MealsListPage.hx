package mealplanner.pages;

import mealplanner.App.appRouter;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.Layout;
import mealplanner.ui.ListView;

using tink.CoreApi;

enum MealsListAction {
	NewMeal(name:String);
}

typedef MealsListParams = {}
typedef MealsList = Array<{name:String, id:String}>

typedef MealsListData = {
	meals:MealsList
};

class MealsListPage implements Page<
	MealsListAction,
	MealsListParams,
	MealsListData
	> {
	public var actionEncoder:IJsonEncoder<MealsListAction> = new JsonEncoder<MealsListAction>();
	public var dataEncoder:IJsonEncoder<MealsListData> = new JsonEncoder<MealsListData>();

	public function new() {}

	public function render(data:MealsListData):Html<MealsListAction> {
		return Layout(SiteHeader("Meals"), MealsListMenu(data.meals));
	}
}

function MealsListMenu(meals:MealsList) {
	final mealLinks = meals.map(
		m -> ListItemLink(m.name, appRouter.uriForMealPage({
			mealId: m.id
		}))
	);
	final newMealInput = ListItemInput("New Meal", "", name -> NewMeal(name));
	final items = mealLinks.concat([newMealInput]);
	return nav([], ListView(items));
}
