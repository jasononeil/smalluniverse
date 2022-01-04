package mealplanner.domains;

import tink.Json;
import smalluniverse.SmallUniverse;
import js.node.Fs;

using tink.CoreApi;
using Lambda;

enum MealsEvent {
	NewMeal(name:String);
	AddIngredient(mealUrl:String, ingredient:String);
	RenameIngredient(
		mealUrl:String,
		oldIngredient:String,
		newIngredient:String
	);
}

typedef MealsModel = {
	meals:Array<{
		slug:String,
		name:String,
		ingredients:Array<{name:String}>
	}>
}

class MealsEventSource implements EventSource<MealsEvent> {
	var eventStore:EventStore<MealsEvent>;
	var jsonFile:String;

	public function new(
		eventStore:EventStore<MealsEvent>,
		writeModelJsonFile:String
	) {
		this.eventStore = eventStore;
		this.jsonFile = writeModelJsonFile;
	}

	public function handleEvent(event:MealsEvent):Promise<EventId> {
		return readModel().next(model -> {
			switch event {
				case NewMeal(name):
					// TODO: validate it doesn't already exist
					// TODO: validate it isn't empty
					model.meals.push({
						name: name,
						slug: getSlugFromName(name),
						ingredients: []
					});
				case AddIngredient(mealSlug, ingredient):
					final matchingMeal = model.meals.find(
						m -> m.slug == mealSlug
					);
					if (matchingMeal == null) {
						final err = new Error(
							BadRequest,
							'Meal with id "${mealSlug}" not found.'
						);
						return Promise.reject(err);
					}
					matchingMeal.ingredients.push({name: ingredient});
				case RenameIngredient(mealSlug, oldIngredient, newIngredient):
					final matchingMeal = model.meals.find(
						m -> m.slug == mealSlug
					);
					if (matchingMeal == null) {
						final err = new Error(
							BadRequest,
							'Meal with id "${mealSlug}" not found.'
						);
						return Promise.reject(err);
					}
					// Rename all ingredients that match the old name with the new name
					matchingMeal.ingredients = matchingMeal.ingredients.map(
						i -> {
							if (i.name == oldIngredient) {
								i.name = newIngredient;
							}
							return i;
						}
					);
			}
			return model;
		}).next(
			model -> writeModel(model)
		).next(_ -> eventStore.publish(event));
	}

	public function getLatestEvent():Promise<Option<EventId>> {
		return eventStore.getLatestEvent();
	}

	public function readEvents(
		numberToRead:Int,
		startingFrom:Option<EventId>
	):Promise<Array<{
		id:EventId,
		payload:MealsEvent
		}>> {
		return eventStore.readEvents(numberToRead, startingFrom);
		}

	public function getMealsList():Promise<Array<{name:String, slug:String}>> {
		return readModel()
				.next(
				model -> model.meals.map(
					meal -> {name: meal.name, slug: meal.slug}
				)
			);
	}

	function readModel():Promise<MealsModel> {
		final trigger = Promise.trigger();
		Fs.readFile(jsonFile, {encoding: "utf8"}, (err, jsonContent) -> {
			if (err != null) {
				trigger.reject(Error.ofJsError(err));
			} else {
				try {
					final model:MealsModel = Json.parse(jsonContent);
					trigger.resolve(model);
				} catch (e) {
					trigger.reject(
						Error.withData(
							501,
							'Failed to parse ${jsonFile} as valid data for our MealsModel: ${e}',
							e
						)
					);
				}
			}
		});
		return trigger.asPromise();
	}

	function writeModel(model:MealsModel):Promise<Noise> {
		final trigger = Promise.trigger();
		final jsonContent = Json.stringify(model);
		Fs.writeFile(jsonFile, jsonContent, {encoding: "utf8"}, (err) -> {
			if (err != null) {
				trigger.reject(Error.ofJsError(err));
			} else {
				trigger.resolve(Noise);
			}
		});
		return trigger.asPromise();
	}

	function getSlugFromName(name:String):String {
		return ~/[^a-zA-Z]/g.replace(name.toLowerCase(), "-");
	}
}
