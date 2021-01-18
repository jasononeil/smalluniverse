package mealplanner.ui;

import mealplanner.AppAction;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

enum ItemAction {
	Action(action:AppAction);
	Link(url:String);
}

function ListView(items:Html<AppAction>):Html<AppAction> {
	return [
		css(CompileTime.readFile("mealplanner/ui/ListView.css")),
		ul([className("ListView__List")], items)
	];
}

function ListItem(content:Html<AppAction>) {
	return div([className("ListView__Content")], content);
}

function ListItemLink(content:Html<AppAction>, url:String) {
	return mealplanner.ui.Link.Link([className("ListView__Content"), href(url)], content);
}

function ListItemButton(content:Html<AppAction>, action:AppAction) {
	// TODO: onClick Action
	return button([className("ListView__Content")], content);
}

function ListItemInput(inputLabel:String, inputValue:String, onChange:String->AppAction) {
	// TODO: onChange Action
	final uniqueId = Std.string(Math.random()); // TODO: use a UUID generator
	return [
		label([className("ListView__SROnly"), htmlFor(uniqueId)], inputLabel),
		inputText([
			id(uniqueId),
			className("ListView__Content"),
			defaultValue(inputValue),
			placeholder(inputLabel)
		]),
	];
}

function ListItemCheckbox(content:Html<AppAction>, ticked:Bool, onChange:Bool->AppAction) {
	// TODO: onChange Action
	return label([className("ListView__Content")], [checkbox([checked(ticked)]), content]);
}
