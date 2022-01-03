package mealplanner;

import mealplanner.App;
import smalluniverse.servers.NodeJs;
import smalluniverse.SmallUniverse;
import smalluniverse.eventlogs.TSVEventStore;
import mealplanner.domains.Meals;
import smalluniverse.orchestrators.SynchronousOrchestrator;

final appOrchestrator = new SynchronousOrchestrator({
	eventSources: [
		new MealsEventSource(
			new TSVEventStore(
				"./example/mealplanner/content/event-stores/events-meals.tsv",
				new JsonEncoder<MealsEvent>()
			),
			"./example/mealplanner/content/write-models/MealsEventSource.json"
		)
	],
	projections: []
});

function main() {
	trace("My meal plan shopping list");
	start(appRouter, appOrchestrator);
}
