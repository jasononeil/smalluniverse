package mealplanner;

import mealplanner.pages.*;
import mealplanner.App;
import smalluniverse.servers.NodeJs;
import smalluniverse.SmallUniverse;
import smalluniverse.eventlogs.TSVEventStore;
import mealplanner.domains.Meals;
import mealplanner.domains.WeeklyPlan;
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

final appOrchestrator = new SynchronousOrchestrator({
	eventSources: [
		mealsEventSource,
		weeklyPlanEventSource
	],
	projections: [],
	pageApis: [
		new IngredientPageApi(),
		new MealPageApi(mealsEventSource),
		new MealsListPageApi(mealsEventSource),
		new ShoppingPageApi(),
		new WeeklyPlanPageApi(weeklyPlanEventSource, mealsEventSource)
	]
});

function main() {
	trace("My meal plan shopping list");
	start(appRouter, appOrchestrator);
}
