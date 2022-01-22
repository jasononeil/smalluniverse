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

final mealsEventSource = new MealsEventSource(
	new TSVEventStore(
		"./example/mealplanner/content/event-stores/events-meals.tsv",
		new JsonEncoder<MealsEvent>()
	),
	"./example/mealplanner/content/write-models/MealsEventSource.json"
);

final weeklyPlanEventSource = new WeeklyPlanEventSource(
	new TSVEventStore(
		"./example/mealplanner/content/event-stores/events-weekly-plan.tsv",
		new JsonEncoder<WeeklyPlanEvent>()
	),
	"./example/mealplanner/content/write-models/WeeklyPlanEventSource.json"
);

final shoppingListEventSource = new ShoppingListEventSource(
	new TSVEventStore(
		"./example/mealplanner/content/event-stores/events-shopping-list.tsv",
		new JsonEncoder<ShoppingListEvent>()
	),
	"./example/mealplanner/content/write-models/ShoppingListEventSource.json"
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
		new MealPageApi(mealsEventSource),
		new MealsListPageApi(mealsEventSource),
		new ShoppingPageApi(shoppingListEventSource),
		new WeeklyPlanPageApi(weeklyPlanEventSource, mealsEventSource)
	]
});

function main() {
	trace("My meal plan shopping list");
	start(appRouter, appOrchestrator);
}
