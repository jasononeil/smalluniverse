package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;

final WeeklyPlanPage = Page(
	new WeeklyPlanView(),
	new WeeklyPlanApi(),
	new JsonEncoder<AppAction>(),
	new JsonEncoder<WeeklyPlanData>()
);

typedef WeeklyPlanParams = {}
typedef WeeklyPlanData = {}

class WeeklyPlanView implements PageView<AppAction, WeeklyPlanData> {
	public function new() {}

	public function render(data:WeeklyPlanData) {
		return Layout(SiteHeader('Weekly plan'), ["my weekly plan"]);
	}
}

class WeeklyPlanApi implements PageApi<
	AppAction,
	WeeklyPlanParams,
	WeeklyPlanData
	> {
	public function new() {}

	public function getPageData(params:WeeklyPlanParams) {
		return {}
	}

	public function pageDataShouldUpdate(
		params:WeeklyPlanParams,
		action:AppAction
	) {
		return false;
	}
}
