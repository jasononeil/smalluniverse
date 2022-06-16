package mealplanner.ui;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

enum ButtonTarget<Action> {
	Link(url:String, ?newWindow:Bool);
	Action(action:Action);
	Submit;
}

function Button<Action>(
	target:ButtonTarget<Action>,
	label:Html<Action>
):Html<Action> {
	return [
		css(CompileTime.readFile("mealplanner/ui/Button.css")),
		switch target {
			case Link(url):
				mealplanner.ui.Link.Link(
					[href(url), className("Button")],
					label
				);
			case Action(action):
				button([
					className("Button"),
					on("click", (e) -> Some(action))
				], label);
			case Submit:
				button([className("Button"), type("submit")], label);
		}
	];
}
