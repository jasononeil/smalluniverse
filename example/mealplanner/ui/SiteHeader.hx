package mealplanner.ui;

import mealplanner.ui.Heading;
import mealplanner.App;
import smalluniverse.DOM;

function SiteHeader(title:String) {
	return [
		css(CompileTime.readFile("mealplanner/ui/SiteHeader.css")),
		header([className("SiteHeader")], [
			Heading1("Meal Planner"),
			nav([], [
				ul([], [
					MenuItem("Meals", appRouter.uriForMealsListPage({})),
					MenuItem("Weekly Plan", appRouter.uriForWeeklyPlanPage({})),
					MenuItem("Shopping List", appRouter.uriForShoppingPage({})),
				])
			]),
			Heading2(title)
		])
	];
}

function MenuItem<PageData>(label:String, uri:String) {
	return li([], a([href(uri)], label));
}
