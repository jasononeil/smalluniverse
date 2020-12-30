package mealplanner.ui;

import mealplanner.pages.ShoppingPage;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.pages.HomePage;
import smalluniverse.SmallUniverse.Page;
import mealplanner.pages.MealPage;
import mealplanner.App.AppRoutes;
import smalluniverse.DOM;
import mealplanner.App.getMockData;

function SiteHeader(title:String) {
	return [
		h1([], title),
		nav([], [
			ul([], [
				MenuItem("Home", HomePage, {}),
				MenuItem("Weekly Plan", WeeklyPlanPage, {}),
				li([], [
					"Meals",
					ul([], getMockData().map(m -> MenuItem(m.name, MealPage, {
						mealId: m.id
					})))
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
