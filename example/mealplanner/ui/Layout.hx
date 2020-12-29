package mealplanner.ui;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.AppAction;

function Layout(headerContent:Html<AppAction>, mainContent:Html<AppAction>) {
	return div([className("container")], [header([], headerContent), main([], mainContent)]);
}
