package mealplanner;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.pages.ShoppingPage;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.pages.HomePage;
import smalluniverse.servers.NodeJs;
import haxe.ds.Option;

function main() {
	trace("My meal plan shopping list");
	start(new AppRoutes());
}

class AppRoutes implements Router {
	public function new() {}

	public function routeToUri<PageParams>(page:Page<Dynamic, PageParams, Dynamic>, params:PageParams):Option<String> {
		// Why use casts here? Haxe forces type compatibility on `enum.equals()`.
		// And it won't treat our loose `page` type as compatible with the specific types of each page.
		// I'm hoping we can have a macro solution to generate these routes that is fully type safe and requires less boilerplate.
		// Why use if/else instead of a switch statement?
		// Because `page` is an enum value, it wants to use pattern matching rather than simple equality checks.
		// This prevents us from having `case ${someVariable}`, so I'm using if/else statements instead.
		if (page.equals(cast HomePage)) {
			return Some("/");
		} else if (page.equals(cast MealPage)) {
			final mealParams:MealParams = cast params;
			return Some('/meal/${mealParams.mealName}');
		} else if (page.equals(cast WeeklyPlanPage)) {
			return Some("/weekly-plan");
		} else if (page.equals(cast ShoppingPage)) {
			return Some("/shopping");
		}
		return None;
	}

	public function uriToRoute(uri:String):Option<{
		page:Page<Dynamic, Dynamic, Dynamic>,
		params:Dynamic
	}> {
		final path = uri.split("?")[0];
		final parts = path.split("/").filter(s -> s != "");
		switch parts {
			case []:
				return Some({page: HomePage, params: {}});
			case ["meal", mealName]:
				return Some({page: MealPage, params: {mealName: mealName}});
			case ["weekly-plan"]:
				return Some({page: WeeklyPlanPage, params: {}});
			case ["shopping"]:
				return Some({page: ShoppingPage, params: {}});
			default:
				return None;
		}
	}
}
