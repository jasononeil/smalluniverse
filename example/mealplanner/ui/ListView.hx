package mealplanner.ui;

import js.html.InputElement;
import js.html.FormElement;
import uuid.Uuid;
import mealplanner.AppAction;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

using tink.CoreApi;

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
	onChange:String->Option<Action>
) {
	final uniqueId = Uuid.v4();
	return form([className("ListView__FormWrapper"), on("submit", (e) -> {
		final form:Null<FormElement> = Std.downcast(e.target, FormElement);
		if (form == null) {
			return None;
		}

		final input = cast(form.elements.namedItem(uniqueId), InputElement);

		e.preventDefault();

		return onChange(input.value);
	})], [label([
		className("ListView__SROnly"),
		htmlFor(uniqueId)
	], inputLabel), inputText([
		className("ListView__Content"),
		id(uniqueId),
		name(uniqueId),
		defaultValue(inputValue),
		placeholder(inputLabel),
		])]);
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
