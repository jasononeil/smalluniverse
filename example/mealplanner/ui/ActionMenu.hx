package mealplanner.ui;

import js.html.InputElement;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import haxe.ds.Option;

using mealplanner.helpers.NullHelper;

// This component is a hacky attempt to do a mobile friendly dropdown without having any control of local state in JS.
// Because I haven't built anything supporting client side state in SmallUniverse yet.
// I'm willing to bet the accessibility of this isn't great.
function ActionMenu<Action>(
	buttonLabel:Html<Action>,
	actions:Map<String, Void->Option<Action>>
):Html<Action> {
	final emptyOption = option([], "");
	final actionOptions = [for (label in actions.keys()) option([], label)];
	return [css(CompileTime.readFile("mealplanner/ui/ActionMenu.css")), label([
		className([
			"ActionMenu",
			"ActionMenu__label"
		])
	], [
		buttonLabel,
		select([
			className("ActionMenu__select"),
			on("change", e -> {
				e.preventDefault();
				final selectedOption:String = (untyped e.target.value);
				final getAction = actions[selectedOption];
				final input:Null<InputElement> = Std.downcast(
					e.target,
					InputElement
				);
				if (input != null) {
					input.value = "";
				}
				if (getAction != null) {
					return getAction();
				}
				return None;
			})
		], [emptyOption].concat(actionOptions))
	])];
}
