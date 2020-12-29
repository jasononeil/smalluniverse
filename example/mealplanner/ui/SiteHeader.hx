package mealplanner.ui;

import mealplanner.pages.ShoppingPage;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.pages.HomePage;
import smalluniverse.SmallUniverse.Page;
import mealplanner.pages.MealPage;
import mealplanner.App.AppRoutes;
import smalluniverse.DOM;

function SiteHeader(title:String) {
	return [
		h1([], title),
		nav([], [
			ul([], [
				MenuItem("Home", HomePage, {}),
				MenuItem("Weekly Plan", WeeklyPlanPage, {}),
				li([], [
					"Meals",
					ul([], [
						MenuItem("Spaghetti", MealPage, {
							mealName: "spaghetti"
						}),
						MenuItem("Tacos", MealPage, {
							mealName: "tacos"
						}),
					])
				]),
				MenuItem("Shopping List", ShoppingPage, {}),
			])
		])
	];
}

function MenuItem<PageData>(label:String, page:Page<Dynamic, PageData, Dynamic>, params:PageData) {
	switch new AppRoutes().routeToUri(page, params) {
		case Some(uri):
			return li([], a([href(uri)], label));
		case None:
			return label;
	}
}
