package mealplanner.ui;

import js.html.AnchorElement;
import js.html.MouseEvent;
import js.html.Event;
import smalluniverse.DOM;
import smalluniverse.SmallUniverse;
import smalluniverse.clients.Browser;

using mealplanner.helpers.NullHelper;

function Link<Action>(
	attrs:Array<HtmlAttribute<Action>>,
	children:Html<Action>
):Html<Action> {
	return a(attrs.concat([on("click", (e:Event) -> {
		final mouseEvent = Std.downcast(e, MouseEvent).sure();
		final link = Std.downcast(e.target, AnchorElement).sure();

		// If this wasn't a plain mouse click (eg, it had modifier keys)
		if (
			mouseEvent.ctrlKey ||
			mouseEvent.shiftKey ||
			mouseEvent.altKey ||
			mouseEvent.metaKey
		) {
			return None;
		}

		triggerNavigation(link.href);
		e.preventDefault();
		return None;
	})]), children);
}
