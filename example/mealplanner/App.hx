package mealplanner;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.pages.ShoppingPage;
import mealplanner.pages.ShopSelectorPage;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.pages.MealsListPage;
import mealplanner.pages.QuickAddPage;
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

	public function uriForWeeklyPlanPage(params:WeeklyPlanParams):String {
		return '/weekly-plan';
	}

	public function uriForShoppingPage(params:ShoppingParams):String {
		return params.showShoppingLinks ? '/shopping/with-links' : '/shopping';
	}

	public function uriForShopSelectorPage(params:ShopSelectorParams):String {
		return '/shopping/select-shop';
	}

	public function uriForQuickAdd(params:QuickAddParams):String {
		return params.input == "" ? '/quick-add' : '/quick-add/${params.input}';
	}

	public function uriToRoute(uri:String):Option<ResolvedRoute<Dynamic>> {
		final path = uri.split("?")[0];
		final parts = path.split("/").filter(s -> s != "");
		switch parts {
			case []:
				return Some(Page(new MealsListPage(), {}));
			case ["meal", mealId]:
				return Some(Page(new MealPage(), {mealId: mealId}));
			case ["weekly-plan"]:
				return Some(Page(new WeeklyPlanPage(), {}));
			case ["shopping", "select-shop"]:
				return Some(Page(new ShopSelectorPage(), {}));
			case ["shopping", "with-links"]:
				return Some(
					Page(new ShoppingPage(), {showShoppingLinks: true})
				);
			case ["shopping"]:
				return Some(
					Page(new ShoppingPage(), {showShoppingLinks: false})
				);
			case ["quick-add"]:
				return Some(Page(new QuickAddPage(), {input: ""}));
			case ["quick-add", input]:
				return Some(Page(new QuickAddPage(), {input: input}));
			default:
				return None;
		}
	}
}

final appRouter = new AppRoutes();
