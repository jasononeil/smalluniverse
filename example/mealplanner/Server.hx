package mealplanner;

import mealplanner.pages.*;
import mealplanner.App;
import smalluniverse.servers.NodeJs;
import smalluniverse.SmallUniverse;
import smalluniverse.eventlogs.TSVEventStore;
import mealplanner.domains.Meals;
import smalluniverse.orchestrators.SynchronousOrchestrator;

final mealsEventSource = new MealsEventSource(
	new TSVEventStore(
		"./example/mealplanner/content/event-stores/events-meals.tsv",
		new JsonEncoder<MealsEvent>()
	),
	"./example/mealplanner/content/write-models/MealsEventSource.json"
);

final appOrchestrator = new SynchronousOrchestrator({
	eventSources: [mealsEventSource],
	projections: [],
	pageApis: [
		new IngredientPageApi(),
		new MealPageApi(mealsEventSource),
		new MealsListPageApi(mealsEventSource),
		new ShoppingPageApi(),
		new WeeklyPlanPageApi()
	]
});

function main() {
	trace("My meal plan shopping list");
	start(appRouter, appOrchestrator);
}
