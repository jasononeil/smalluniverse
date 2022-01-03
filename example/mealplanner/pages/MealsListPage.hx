package mealplanner.pages;

import mealplanner.App.appRouter;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.Layout;
import mealplanner.ui.ListView;
import mealplanner.App.getMockData;
import mealplanner.domains.Meals;

using tink.CoreApi;

enum MealsListAction {
	NewMeal(name:String);
}

final MealsListPage = Page(
	new MealsListView(),
	new MealsListApi(
		new MealsEventSource(
			untyped {}, // TODO: trying to instantiate this here, in a spot compiled by the client, is annoying and I'm doing dumb hacks to work around it.
			"./example/mealplanner/content/write-models/MealsEventSource.json"
		)
	),
	new JsonEncoder<MealsListAction>(),
	new JsonEncoder<MealsListData>()
);

typedef MealsListParams = {}
typedef MealsList = Array<{name:String, id:String}>

typedef MealsListData = {
	meals:MealsList
};

class MealsListView implements PageView<MealsListAction, MealsListData> {
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

class MealsListApi implements PageApi<
	MealsListAction,
	MealsListParams,
	MealsListData
	> {
	var mealsModel:MealsEventSource;

	public function new(mealsModel:MealsEventSource) {
		this.mealsModel = mealsModel;
	}

	public function getPageData(params:MealsListParams):Promise<MealsListData> {
		return mealsModel.getMealsList().next(meals -> {
			return {
				meals: meals.map(m -> {
					name: m.name,
					id: m.slug
				})
			};
		});
	}

	public function actionToCommand(
		params:MealsListParams,
		action:MealsListAction
	) {
		switch action {
			case NewMeal(name):
				return new Command(MealsEventSource, NewMeal(name));
		}
	}
}
