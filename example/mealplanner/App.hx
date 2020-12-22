package mealplanner;

import smalluniverse.SmallUniverse;
import mealplanner.pages.MealPage;
import mealplanner.pages.ShoppingPage;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.pages.HomePage;
import haxe.ds.Option;

function main() {
	trace("My meal plan shopping list");
}

class AppRoutes implements Router {
	var routes:Array<{pathname:String, page:Page<Dynamic, Dynamic, Dynamic>, params:Dynamic}> = [
		{pathname: "/", page: HomePage, params: {}},
		{pathname: "/meal", page: MealPage, params: {}},
		{pathname: "/weekly-plan", page: WeeklyPlanPage, params: {}},
		{pathname: "/shopping", page: ShoppingPage, params: {}},
	];

	public function routeToUri<PageAction, PageParams>(page, params) {
		for (route in routes) {
			if (Type.enumEq(route.page, page)) {
				return Some(route.pathname);
			}
		}
		return None;
	}

	public function uriToRoute<PageParams>(uri) {
		for (route in routes) {
			if (route.pathname == uri) {
				return Some({page: route.page, params: route.params});
			}
		}
		return None;
	}
}
