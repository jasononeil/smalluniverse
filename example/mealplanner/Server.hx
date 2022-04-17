package mealplanner;

import mealplanner.pages.*;
import mealplanner.App;
import smalluniverse.servers.NodeJs;
import smalluniverse.SmallUniverse;
import smalluniverse.eventlogs.TSVEventStore;
import mealplanner.domains.Meals;
import mealplanner.domains.WeeklyPlan;
import mealplanner.domains.ShoppingList;
import smalluniverse.orchestrators.SynchronousOrchestrator;
import js.node.Fs;

final mealsEventSource = new MealsEventSource(
	new TSVEventStore(
		"./app-content/event-stores/events-meals.tsv",
		new JsonEncoder<MealsEvent>()
	),
	"./app-content/write-models/MealsEventSource.json"
);

final weeklyPlanEventSource = new WeeklyPlanEventSource(
	new TSVEventStore(
		"./app-content/event-stores/events-weekly-plan.tsv",
		new JsonEncoder<WeeklyPlanEvent>()
	),
	"./app-content/write-models/WeeklyPlanEventSource.json"
);

final shoppingListEventSource = new ShoppingListEventSource(
	new TSVEventStore(
		"./app-content/event-stores/events-shopping-list.tsv",
		new JsonEncoder<ShoppingListEvent>()
	),
	"./app-content/write-models/ShoppingListEventSource.json"
);

final appOrchestrator = new SynchronousOrchestrator({
	eventSources: [
		mealsEventSource,
		weeklyPlanEventSource,
		shoppingListEventSource
	],
	projections: [],
	pageApis: [
		new IngredientPageApi(),
		new MealPageApi(mealsEventSource, shoppingListEventSource),
		new MealsListPageApi(mealsEventSource),
		new ShoppingPageApi(shoppingListEventSource),
		new ShopSelectorPageApi(shoppingListEventSource),
		new WeeklyPlanPageApi(weeklyPlanEventSource, mealsEventSource)
	]
});

function main() {
	trace("My meal plan shopping list");
	start(appRouter, appOrchestrator);
}
