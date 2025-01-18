package mealplanner.domains;

import smalluniverse.eventsources.JsonFileEventSource;
import mealplanner.helpers.DateString;
import smalluniverse.SmallUniverse;

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

class WeeklyPlanEventSource extends JsonFileEventSource<
	WeeklyPlanEvent,
	WeeklyPlanModel
	> {
	public function new(
		eventStore:EventStore<WeeklyPlanEvent>,
		writeModelJsonFile:String,
		bookmarkManager:BookmarkManager
	) {
		super(
			eventStore,
			writeModelJsonFile,
			new JsonEncoder<WeeklyPlanModel>(),
			update,
			bookmarkManager
		);
	}

	function update(
		model:WeeklyPlanModel,
		event:WeeklyPlanEvent
	):Promise<WeeklyPlanModel> {
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
}
