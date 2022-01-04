package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.pages.WeeklyPlanPage;

using tink.CoreApi;

class WeeklyPlanPageApi implements PageApi<
	AppAction,
	WeeklyPlanParams,
	WeeklyPlanData
	> {
	public var relatedPage = WeeklyPlanPage;

	public function new() {}

	public function getPageData(
		params:WeeklyPlanParams
	):Promise<WeeklyPlanData> {
		return {}
	}

	public function actionToCommand(pageParams, action) {
		// TODO
		return Command.DoNothing;
	}
}
