package mealplanner;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.pages.ShoppingPage;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.pages.MealsListPage;
import mealplanner.pages.IngredientPage;
import haxe.ds.Option;

// function getMockData() {
// 	return CompileTime.parseJsonFile("mealplanner/sample-data.json");
// }

class AppRoutes implements Router {
	public function new() {}

	// I'm hoping we can have a macro solution to generate these routes that is fully type safe and requires less boilerplate.

	public function uriForMealsListPage(params:MealsListParams):String {
		return '/';
	}

	public function uriForMealPage(params:MealParams):String {
		return '/meal/${params.mealId}';
	}

	public function uriForIngredientPage(params:IngredientParams):String {
		return '/ingredient/${params.ingredient}';
	}

	public function uriForWeeklyPlanPage(params:WeeklyPlanParams):String {
		return '/weekly-plan';
	}

	public function uriForShoppingPage(params:ShoppingParams):String {
		return '/shopping';
	}

	public function uriToRoute(uri:String):Option<ResolvedRoute<Dynamic>> {
		final path = uri.split("?")[0];
		final parts = path.split("/").filter(s -> s != "");
		switch parts {
			case []:
				return Some(Page(new MealsListPage(), {}));
			case ["meal", mealId]:
				return Some(Page(new MealPage(), {mealId: mealId}));
			case ["ingredient", ingredientName]:
				return Some(Page(new IngredientPage(), {
					ingredient: StringTools.urlDecode(ingredientName)
				}));
			case ["weekly-plan"]:
				return Some(Page(new WeeklyPlanPage(), {}));
			case ["shopping"]:
				return Some(Page(new ShoppingPage(), {}));
			default:
				return None;
		}
	}
}

final appRouter = new AppRoutes();
