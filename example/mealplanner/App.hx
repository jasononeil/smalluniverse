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

	public function routeToUri<PageAction, PageParams>(page, params) {
		return switch page {
			case HomePage:
				Some("/");
			case MealPage:
				Some("meal");
			case WeeklyPlanPage:
				Some("weekly-plan");
			case ShoppingPage:
				Some("/shopping");
			default:
				None;
		}
	}

	public function uriToRoute<PageParams>(uri:String) {
		page:Page<Dynamic, Dynamic, Dynamic>, params:Dynamic
	} {

		final path = uri.split("?")[0];
		final parts = path.split("/").filter(s -> s != "");
		return switch parts {
			case []:
				Some({page: HomePage, params: {}});
			case ["meal"]:
				Some({page: MealPage, params: {}});
			case ["weekly-plan"]:
				Some({page: WeeklyPlanPage, params: {}});
			case ["shopping"]:
				Some({page: ShoppingPage, params: {}});
			default:
				None;
		}
	}
}
