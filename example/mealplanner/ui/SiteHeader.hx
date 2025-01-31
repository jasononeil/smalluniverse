package mealplanner.ui;

import mealplanner.ui.Heading;
import mealplanner.ui.Link;
import mealplanner.App;
import smalluniverse.DOM;
import smalluniverse.SmallUniverse.Html;

function SiteHeader<Action>(title:String):Html<Action> {
	return [css(CompileTime.readFile("mealplanner/ui/SiteHeader.css")), header([
		className("SiteHeader")
	], [
		Heading1("Meal Planner"),
		nav([], [
			ul([], [
				MenuItem("Meals", appRouter.uriForMealsListPage({})),
				MenuItem("Weekly Plan", appRouter.uriForWeeklyPlanPage({})),
				MenuItem("Shopping List", appRouter.uriForShoppingPage({
					showShoppingLinks: false
				})),
				MenuItem("Quick Add", appRouter.uriForQuickAdd({
					input: ""
				})),
			])
		]),
		Heading2(title)
	])];
}

function MenuItem<PageData>(label:String, uri:String) {
	return li([], Link([href(uri)], label));
}
