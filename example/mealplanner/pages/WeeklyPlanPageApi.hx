package mealplanner.pages;

import mealplanner.helpers.DateString;
import mealplanner.Server.weeklyPlanEventSource;
import smalluniverse.SmallUniverse;
import mealplanner.pages.WeeklyPlanPage;
import mealplanner.domains.WeeklyPlan;
import mealplanner.domains.Meals;
import datetime.DateTime;

using tink.CoreApi;
using Lambda;

class WeeklyPlanPageApi implements PageApi<
	WeeklyPlanAction,
	WeeklyPlanParams,
	WeeklyPlanData
	> {
	public var relatedPage = WeeklyPlanPage;

	var mealsEventSource:MealsEventSource;
	var weeklyPlanEventSource:WeeklyPlanEventSource;

	public function new(
		weeklyPlanEventSource:WeeklyPlanEventSource,
		mealsEventSource:MealsEventSource
	) {
		this.weeklyPlanEventSource = weeklyPlanEventSource;
		this.mealsEventSource = mealsEventSource;
	}

	public function getPageData(
		params:WeeklyPlanParams
	):Promise<WeeklyPlanData> {
		// We're only dealing with dates, not times, so leaving everything UTC feels the least complicated.
		final utcNow = DateTime.now();
		final today = utcNow.snap(Day(Down));

		// Allow planning up to 14 days in advance
		final dates = [for (i in 0...14) today.add(Day(i))];

		final plansPromise = weeklyPlanEventSource.getPlansForDates(
			dates.map(date -> DateString.fromDateTime(date))
		);

		final mealsListPromise = mealsEventSource.getMealsList();

		return (plansPromise && mealsListPromise).next(pair -> {
			final plansForDates = pair.a;
			final mealList = pair.b;
			return {
				dates: plansForDates.map(d -> {
					date: d.date,
					meals: d.plan.meals.map(meal -> {
						id: meal.mealId,
						name: getMealName(mealList, meal.mealId)
					}),
					note: d.plan.note
				}),
				availableMeals: mealList.map(m -> {
					id: m.slug,
					name: m.name
				})
			};
		});
	}

	public function actionToCommand(
		pageParams,
		action:WeeklyPlanAction
	):Command<Any> {
		switch action {
			case AddMealToDay(date, meal):
				return new Command(
					WeeklyPlanEventSource,
					AddMealToDay(date, meal)
				);
			case RemoveMealFromDay(date, meal):
				return new Command(
					WeeklyPlanEventSource,
					RemoveMealFromDay(date, meal)
				);
			case SetNote(date, note):
				return new Command(WeeklyPlanEventSource, SetNote(date, note));
		}
	}
}

function getMealName(
	mealsList:Array<{slug:String, name:String}>,
	mealSlug:String
):String {
	final meal = mealsList.find(meal -> meal.slug == mealSlug);
	return meal != null ? meal.name : mealSlug;
}
