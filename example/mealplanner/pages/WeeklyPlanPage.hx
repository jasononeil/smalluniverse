package mealplanner.pages;

import mealplanner.ui.Button;
import mealplanner.ui.CalendarGrid;
import mealplanner.helpers.DateString;
import js.html.SelectElement;
import mealplanner.App.appRouter;
import mealplanner.ui.ListView;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;
import mealplanner.ui.Heading;

using tink.CoreApi; /** All dates are in the format yyyy-mm-dd **/

enum WeeklyPlanAction {
	AddMealToDay(date:DateString, meal:String);
	RemoveMealFromDay(date:DateString, meal:String);
	SetNote(date:DateString, note:String);
}

typedef WeeklyPlanParams = {}

typedef WeeklyPlanData = {
	dates:Array<MealPlanForDate>,
	availableMeals:Array<{name:String, id:String}>
}

typedef MealPlanForDate = {
	date:DateString,
	note:String,
	meals:Array<{name:String, id:String}>
}

class WeeklyPlanPage implements Page<
	WeeklyPlanAction,
	WeeklyPlanParams,
	WeeklyPlanData
	> {
	public var actionEncoder:IJsonEncoder<WeeklyPlanAction> = new JsonEncoder<WeeklyPlanAction>();
	public var dataEncoder:IJsonEncoder<WeeklyPlanData> = new JsonEncoder<WeeklyPlanData>();

	public function new() {}

	public function render(data:WeeklyPlanData) {
		return Layout(
			SiteHeader('Weekly plan'),
			CalendarGrid(data.dates.map(planForDate -> {
				date: planForDate.date.toDateTime(),
				content: renderPlanForDate(planForDate, data.availableMeals)
			}))
		);
	}

	function renderPlanForDate(
		planForDate:MealPlanForDate,
		availableMeals:Array<{
			name:String,
			id:String
		}>
	):Html<WeeklyPlanAction> {
		final date = planForDate.date.toDateTime();
		final dayInMonth = date.format("%d");
		final month = months[date.getMonth() - 1];

		return [Heading3([weekdays[
			date.getWeekDay()
		], element("small", [], ' ($dayInMonth $month)')]), ListView([

			planForDate.meals.map(meal -> {
				final mealUrl = appRouter.uriForMealPage({mealId: meal.id});
				return ListItemLink(meal.name, mealUrl);
			}),
			renderMealSelect(date, availableMeals),
			ListItemInput(
				'Notes',
				planForDate.note,
				note -> Some(SetNote(planForDate.date, note))
			),
			])];
	}
}

function renderMealSelect(
	date,
	availableMeals:Array<{name:String, id:String}>
) {
	final blankOption = option([defaultValue("")], "Select a meal...");
	final mealOptions = availableMeals.map(m -> {
		option([defaultValue(m.id)], m.name);
	});
	return form([onSubmit(form -> {
		final select = cast(form.elements.namedItem("mealId"), SelectElement);
		return (select.value == "") ? None : Some(
			AddMealToDay(date, select.value)
		);
	})], [select([name("mealId")], [
		blankOption
	].concat(mealOptions)), Button(Submit, "Add meal")]);
}

final weekdays = [
	"Sunday",
	"Monday",
	"Tuesday",
	"Wednesday",
	"Thursday",
	"Friday",
	"Saturday"
];

final months = [
	"Jan",
	"Feb",
	"Mar",
	"Apr",
	"May",
	"Jun",
	"Jul",
	"Oct",
	"Nov",
	"Dec"
];
