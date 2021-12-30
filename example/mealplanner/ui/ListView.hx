package mealplanner.ui;

import mealplanner.AppAction;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

enum ItemAction {
	Action(action:AppAction);
	Link(url:String);
}

function ListView<Action>(items:Html<Action>):Html<Action> {
	return [css(CompileTime.readFile("mealplanner/ui/ListView.css")), ul([
		className("ListView__List")
	], items)];
}

function ListItem<Action>(content:Html<Action>) {
	return div([className("ListView__Content")], content);
}

function ListItemLink<Action>(content:Html<Action>, url:String) {
	return mealplanner.ui.Link.Link([
		className("ListView__Content"),
		href(url)
	], content);
}

function ListItemButton<Action>(content:Html<Action>, action:Action) {
	// TODO: onClick Action
	return button([className("ListView__Content")], content);
}

function ListItemInput<Action>(
	inputLabel:String,
	inputValue:String,
	onChange:String->Action
) {
	// TODO: onChange Action
	final uniqueId = Std.string(Math.random()); // TODO: use a UUID generator
	return [label([
		className("ListView__SROnly"),
		htmlFor(uniqueId)
	], inputLabel), inputText([
		id(uniqueId),
		className("ListView__Content"),
		defaultValue(inputValue),
		placeholder(inputLabel),
		on("change", e -> {
			final input:Null<js.html.InputElement> = Std.downcast(
				e.target,
				js.html.InputElement
			);
			if (input == null) {
				return None;
			}

			return Some(onChange(input.value));
		})
		]),];
}

function ListItemCheckbox<Action>(
	content:Html<Action>,
	ticked:Bool,
	onChange:Bool->Action
) {
	// TODO: onChange Action
	return label([className("ListView__Content")], [checkbox([
		checked(ticked)
	]), content]);
}
