package mealplanner.pages;

import smalluniverse.SmallUniverse;
import mealplanner.ui.Layout;
import mealplanner.ui.SiteHeader;

using tink.CoreApi;

typedef WeeklyPlanParams = {}
typedef WeeklyPlanData = {}

class WeeklyPlanPage implements Page<
	AppAction,
	WeeklyPlanParams,
	WeeklyPlanData
	> {
	public var actionEncoder:IJsonEncoder<AppAction> = new JsonEncoder<AppAction>();
	public var dataEncoder:IJsonEncoder<WeeklyPlanData> = new JsonEncoder<WeeklyPlanData>();

	public function new() {}

	public function render(data:WeeklyPlanData) {
		return Layout(SiteHeader('Weekly plan'), ["my weekly plan"]);
	}
}
