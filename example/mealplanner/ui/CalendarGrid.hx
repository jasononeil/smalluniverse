package mealplanner.ui;

import datetime.DateTime;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

function CalendarGrid<Action>(
	dates:Array<{date:DateTime, content:Html<Action>}>
) {
	return [css(CompileTime.readFile("mealplanner/ui/CalendarGrid.css")), div([
		className("CalendarGrid")
	], dates.map(d -> section([
		className([
			"CalendarGrid__DaySquare",
			'CalendarGrid__DaySquare--Day_${d.date.getWeekDay()}'
		]),
		], d.content)))];
}
