package mealplanner.ui;

import js.html.Event;
import js.Browser.window;
import js.Browser.location;
import smalluniverse.DOM;
import smalluniverse.SmallUniverse;
import smalluniverse.clients.Browser;

function Link<Action>(
	attrs:Array<HtmlAttribute<Action>>,
	children:Html<Action>
):Html<Action> {
	return a(attrs.concat([on("click", (e:Event) -> {
		final url:String = untyped e.target.href;
		triggerNavigation(url);
		e.preventDefault();
		return None;
	})]), children);
}
