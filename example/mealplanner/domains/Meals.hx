package mealplanner.domains;

import smalluniverse.eventsources.JsonFileEventSource;
import tink.Json;
import smalluniverse.SmallUniverse;
import js.node.Fs;

using tink.CoreApi;
using Lambda;

enum MealsEvent {
	NewMeal(name:String);
	RenameMeal(oldId:String, newName:String);
	DeleteMeal(mealId:String);
	AddIngredient(meal:String, ingredient:String);
	RenameIngredient(meal:String, oldIngredient:String, newIngredient:String);
	DeleteIngredient(meal:String, ingredient:String);
}

typedef MealsModel = {
	meals:Array<Meal>
}

typedef Meal = {
	slug:String,
	name:String,
	ingredients:Array<{name:String}>
}

class MealsEventSource extends JsonFileEventSource<MealsEvent, MealsModel> {
	public function new(
		eventStore:EventStore<MealsEvent>,
		writeModelJsonFile:String,
		bookmarkManager:BookmarkManager
	) {
		super(
			eventStore,
			writeModelJsonFile,
			new JsonEncoder<MealsModel>(),
			update,
			bookmarkManager
		);
	}

	function update(model:MealsModel, event:MealsEvent):Promise<MealsModel> {
		switch event {
			case NewMeal(name):
				final slug = getSlugFromName(name);
				if (name == "" || slug == "") {
					return Promise.reject(
						new Error(
							BadRequest,
							'Cannot create a meal with no name'
						)
					);
				}
				if (model.meals.find(
					m -> m.slug == getSlugFromName(name)
				) != null) {
					return Promise.reject(
						new Error(
							BadRequest,
							'A meal with ID ${slug} already exists'
						)
					);
				}
				model.meals.push({
					name: name,
					slug: getSlugFromName(name),
					ingredients: []
				});
			case RenameMeal(oldId, newName):
				final newSlug = getSlugFromName(newName);
				if (newName == "" || newSlug == "") {
					return Promise.reject(
						new Error(BadRequest, 'The new meal name was blank')
					);
				}
				final matchingMeal = model.meals.find(m -> m.slug == oldId);
				if (matchingMeal == null) {
					final err = new Error(
						BadRequest,
						'Old meal with name "${oldId}" not found.'
					);
					return Promise.reject(err);
				}
				matchingMeal.name = newName;
				matchingMeal.slug = newSlug;
			case DeleteMeal(name):
				final slug = getSlugFromName(name);
				if (name == "" || slug == "") {
					return Promise.reject(
						new Error(
							BadRequest,
							'Cannot delete a meal with no name'
						)
					);
				}
				model.meals = model.meals.filter(meal -> meal.slug != slug);
			case AddIngredient(mealSlug, ingredient):
				final matchingMeal = model.meals.find(m -> m.slug == mealSlug);
				if (matchingMeal == null) {
					final err = new Error(
						BadRequest,
						'Meal with id "${mealSlug}" not found.'
					);
					return Promise.reject(err);
				}
				matchingMeal.ingredients.push({name: ingredient});
			case RenameIngredient(mealId, oldIngredient, newIngredient):
				final matchingMeal = model.meals.find(m -> m.slug == mealId);
				if (matchingMeal == null) {
					final err = new Error(
						BadRequest,
						'Meal with id "${mealId}" not found.'
					);
					return Promise.reject(err);
				}
				// Rename all ingredients that match the old name with the new name
				matchingMeal.ingredients = matchingMeal.ingredients.map(i -> {
					if (i.name == oldIngredient) {
						i.name = newIngredient;
					}
					return i;
				});
			case DeleteIngredient(mealId, ingredient):
				final matchingMeal = model.meals.find(m -> m.slug == mealId);
				if (matchingMeal == null) {
					final err = new Error(
						BadRequest,
						'Meal with id "${mealId}" not found.'
					);
					return Promise.reject(err);
				}
				matchingMeal.ingredients = matchingMeal.ingredients.filter(
					i -> i.name != ingredient
				);
		}
		return model;
	}

	public function getMealsList():Promise<Array<{name:String, slug:String}>> {
		return readModel()
				.next(
				model -> model.meals.map(
					meal -> {name: meal.name, slug: meal.slug}
				)
			);
	}

	public function getMeal(slug:String):Promise<Meal> {
		return readModel()
				.next(model -> model.meals.find(meal -> meal.slug == slug))
				.next(meal -> {
				if (meal == null) {
					return Promise.reject(
						new Error(NotFound, 'Meal $slug not found')
					);
				}
				return meal;
			});
	}

	public function getAllIngredients():Promise<Array<{name:String, meal:{id:String, name:String}}>> {
		return readModel().next(model -> {
			model.meals.map(meal -> meal.ingredients.map(i -> {
				name: i.name,
				meal: {
					id: meal.slug,
					name: meal.name
				}
			})).flatten();
		});
	}

	function getSlugFromName(name:String):String {
		return ~/[^a-zA-Z]/g.replace(name.toLowerCase(), "-");
	}
}
