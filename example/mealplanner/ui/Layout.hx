package mealplanner.ui;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.AppAction;

function Layout(headerContent:Html<AppAction>, mainContent:Html<AppAction>):Html<AppAction> {
	return [
		css(CompileTime.readFile("node_modules/normalize.css/normalize.css")),
		div([className("container")], [header([], headerContent), main([], mainContent)])
	];
}
