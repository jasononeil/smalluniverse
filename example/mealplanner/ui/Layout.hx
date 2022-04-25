package mealplanner.ui;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

using mealplanner.helpers.NullHelper;

final sourceSansVariableUrl = "https://cdn.jsdelivr.net/npm/source-sans-pro@3.6.0/source-sans-variable.css";

function Layout<Action>(
	headerContent:Html<Action>,
	mainContent:Html<Action>,
	?attributes:Array<HtmlAttribute<Action>>
):Html<Action> {
	return div(attributes.or([]), [
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
