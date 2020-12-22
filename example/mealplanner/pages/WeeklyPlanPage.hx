package mealplanner.pages;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

final WeeklyPlanPage = Page(new WeeklyPlanView(), new WeeklyPlanApi());
typedef WeeklyPlanParams = {}
typedef WeeklyPlanData = {}

class WeeklyPlanView implements PageView<AppAction, WeeklyPlanData> {
	public function new() {}

	public function render(data:WeeklyPlanData) {
		return h1([], [text("My weekly plan!")]);
	}
}

class WeeklyPlanApi implements PageApi<AppAction, WeeklyPlanParams, WeeklyPlanData> {
	public function new() {}

	public function getPageData(params:WeeklyPlanParams) {
		return {}
	}

	public function pageDataShouldUpdate(params:WeeklyPlanParams, action:AppAction) {
		return false;
	}
}
