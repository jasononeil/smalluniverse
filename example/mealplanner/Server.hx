package mealplanner;

import smalluniverse.bookmarks.JsonBookmarkManager;
import mealplanner.pages.*;
import mealplanner.App;
import smalluniverse.servers.NodeJs;
import smalluniverse.SmallUniverse;
import smalluniverse.eventlogs.TSVEventStore;
import mealplanner.domains.Meals;
import mealplanner.domains.WeeklyPlan;
import mealplanner.domains.ShoppingList;
import smalluniverse.orchestrators.SynchronousOrchestrator;

final bookmarkManager = new JsonBookmarkManager(
	"./app-content/write-models/bookmarks.json"
);

final mealsEventSource = new MealsEventSource(
	new TSVEventStore(
		"./app-content/event-stores/events-meals.tsv",
		new JsonEncoder<MealsEvent>()
	),
	"./app-content/write-models/MealsEventSource.json",
	bookmarkManager
);

final weeklyPlanEventSource = new WeeklyPlanEventSource(
	new TSVEventStore(
		"./app-content/event-stores/events-weekly-plan.tsv",
		new JsonEncoder<WeeklyPlanEvent>()
	),
	"./app-content/write-models/WeeklyPlanEventSource.json",
	bookmarkManager
);

final shoppingListEventSource = new ShoppingListEventSource(
	new TSVEventStore(
		"./app-content/event-stores/events-shopping-list.tsv",
		new JsonEncoder<ShoppingListEvent>()
	),
	"./app-content/write-models/ShoppingListEventSource.json",
	bookmarkManager
);

final appOrchestrator = new SynchronousOrchestrator({
	eventSources: [
		mealsEventSource,
		weeklyPlanEventSource,
		shoppingListEventSource
	],
	projections: [],
	pageApis: [
		new MealPageApi(mealsEventSource, shoppingListEventSource),
		new MealsListPageApi(mealsEventSource),
		new ShoppingPageApi(shoppingListEventSource),
		new ShopSelectorPageApi(shoppingListEventSource),
		new WeeklyPlanPageApi(weeklyPlanEventSource, mealsEventSource),
		new QuickAddPageApi(mealsEventSource, shoppingListEventSource),
	]
});

function main() {
	trace("My meal plan shopping list");
	start(appRouter, appOrchestrator);
}
