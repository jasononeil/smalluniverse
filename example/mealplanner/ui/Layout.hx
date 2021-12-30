package mealplanner.ui;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.AppAction;

final sourceSansVariableUrl = "https://cdn.jsdelivr.net/npm/source-sans-pro@3.6.0/source-sans-variable.css";

function Layout(
	headerContent:Html<AppAction>,
	mainContent:Html<AppAction>
):Html<AppAction> {
	return div([], [
		css(CompileTime.readFile("mealplanner/ui/Variables.css")),
		css(CompileTime.readFile("mealplanner/ui/Layout.css")),
		link([
			rel("stylesheet"),
			href(sourceSansVariableUrl)
		]),
		css(CompileTime.readFile("node_modules/normalize.css/normalize.css")),
		div([
			className("Layout__Container")
		], [
			header([], headerContent),
			main([], mainContent)
		])
	]);
}
