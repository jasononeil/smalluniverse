package mealplanner;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.pages.ShoppingPage;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.pages.MealsListPage;
import mealplanner.pages.IngredientPage;
import smalluniverse.servers.NodeJs;
import haxe.ds.Option;

function main() {
	trace("My meal plan shopping list");
	start(new AppRoutes());
}

function getMockData() {
	return CompileTime.parseJsonFile("mealplanner/sample-data.json");
}

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

	public function uriToRoute(uri:String):Option<{
		page:Page<Dynamic, Dynamic, Dynamic>,
		params:Dynamic
	}> {
		final path = uri.split("?")[0];
		final parts = path.split("/").filter(s -> s != "");
		switch parts {
			case []:
				return Some({page: MealsListPage, params: {}});
			case ["meal", mealId]:
				return Some({page: MealPage, params: {mealId: mealId}});
			case ["ingredient", ingredientName]:
				return Some({page: IngredientPage, params: {ingredient: StringTools.urlDecode(ingredientName)}});
			case ["weekly-plan"]:
				return Some({page: WeeklyPlanPage, params: {}});
			case ["shopping"]:
				return Some({page: ShoppingPage, params: {}});
			default:
				return None;
		}
	}
}

final appRouter = new AppRoutes();
