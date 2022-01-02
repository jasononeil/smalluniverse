package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;

using tink.CoreApi;

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
