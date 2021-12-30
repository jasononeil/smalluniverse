package mealplanner.pages;

import mealplanner.App.appRouter;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.Layout;
import mealplanner.ui.ListView;
import mealplanner.App.getMockData;

final MealsListPage = Page(
	new MealsListView(),
	new MealsListApi(),
	new JsonEncoder<AppAction>(),
	new JsonEncoder<MealsListData>()
);

typedef MealsListParams = {}
typedef MealsList = Array<{name:String, id:String}>

typedef MealsListData = {
	meals:MealsList
};

class MealsListView implements PageView<AppAction, MealsListData> {
	public function new() {}

	public function render(data:MealsListData):Html<AppAction> {
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

class MealsListApi implements PageApi<
	AppAction,
	MealsListParams,
	MealsListData
	> {
	public function new() {}

	public function getPageData(params:MealsListParams) {
		return {
			meals: getMockData().map(m -> {name: m.name, id: m.id})
		};
	}

	public function pageDataShouldUpdate(
		params:MealsListParams,
		action:AppAction
	) {
		return false;
	}
}
