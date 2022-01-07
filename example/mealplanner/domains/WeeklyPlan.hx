package mealplanner.domains;

import mealplanner.helpers.DateString;
import tink.Json;
import smalluniverse.SmallUniverse;
import js.node.Fs;

using tink.CoreApi;
using Lambda;

enum WeeklyPlanEvent {
	AddMealToDay(date:String, meal:String);
	RemoveMealFromDay(date:String, meal:String);
	SetNote(date:String, note:String);
}

typedef WeeklyPlanModel = {
	plansForDates:Map<DateString, PlanForDate>
}

typedef PlanForDate = {
	note:String,
	meals:Array<{mealId:String}>
}

class WeeklyPlanEventSource extends BasicEventSource<WeeklyPlanEvent> {
	var jsonFile:String;

	public function new(
		eventStore:EventStore<WeeklyPlanEvent>,
		writeModelJsonFile:String
	) {
		super(eventStore);
		this.jsonFile = writeModelJsonFile;
	}

	override public function handleEvent(
		event:WeeklyPlanEvent
	):Promise<EventId> {
		return readModel().next(model -> {
			switch event {
				case AddMealToDay(date, meal):
					getPlanForDate(model, date).meals.push({mealId: meal});
				case RemoveMealFromDay(date, meal):
					final plan = getPlanForDate(model, date);
					plan.meals = plan.meals.filter(m -> m.mealId != meal);
				case SetNote(date, note):
					getPlanForDate(model, date).note = note;
			}
			return model;
		}).next(
			model -> writeModel(model)
		).next(_ -> this.store.publish(event));
	}

	public function getPlansForDates(
		dates:Array<DateString>
	):Promise<Array<{date:DateString, plan:PlanForDate}>> {
		return readModel().next(model -> {
			return [for (date in dates) {
				date: date,
				plan: getPlanForDate(model, date)
			}];
		});
	}

	function getPlanForDate(
		model:WeeklyPlanModel,
		date:DateString
	):PlanForDate {
		final plan = model.plansForDates[date];
		if (plan == null) {
			final newPlan = {
				note: "",
				meals: []
			};
			model.plansForDates[date] = newPlan;
			return newPlan;
		}
		return plan;
	}

	function readModel():Promise<WeeklyPlanModel> {
		final trigger = Promise.trigger();
		Fs.readFile(jsonFile, {encoding: "utf8"}, (err, jsonContent) -> {
			if (err != null) {
				trigger.reject(Error.ofJsError(err));
			} else {
				try {
					final model:WeeklyPlanModel = Json.parse(jsonContent);
					trigger.resolve(model);
				} catch (e) {
					trigger.reject(
						Error.withData(
							501,
							'Failed to parse ${jsonFile} as valid data for our WeeklyPlanModel: ${e}',
							e
						)
					);
				}
			}
		});
		return trigger.asPromise();
	}

	function writeModel(model:WeeklyPlanModel):Promise<Noise> {
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
}
