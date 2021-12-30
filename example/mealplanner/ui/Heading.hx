package mealplanner.ui;

import mealplanner.AppAction;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

enum abstract HeadingTag(String) to String {
	var H1;
	var H2;
	var H3;
}

function Heading<T>(tag:HeadingTag, content:Html<T>):Html<T> {
	return [
		css(CompileTime.readFile("mealplanner/ui/Heading.css")),
		element(tag, [
			className([
				"Heading",
				'Heading--$tag'
			])
		], content)
	];
}

inline function Heading1<Action>(content:Html<Action>):Html<Action> {
	return Heading(H1, content);
}

inline function Heading2<Action>(content:Html<Action>):Html<Action> {
	return Heading(H2, content);
}

inline function Heading3<Action>(content:Html<Action>):Html<Action> {
	return Heading(H3, content);
}
