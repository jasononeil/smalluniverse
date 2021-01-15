package mealplanner.ui;

import mealplanner.AppAction;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

enum abstract HeadingTag(String) to String {
	var H1;
	var H2;
	var H3;
}

function Heading(tag:HeadingTag, content:Html<AppAction>):Html<AppAction> {
	return [
		css(CompileTime.readFile("mealplanner/ui/Heading.css")),
		element(tag, [className(["Heading", 'Heading--$tag'])], content)
	];
}

inline function Heading1(content:Html<AppAction>):Html<AppAction> {
	return Heading(H1, content);
}

inline function Heading2(content:Html<AppAction>):Html<AppAction> {
	return Heading(H2, content);
}

inline function Heading3(content:Html<AppAction>):Html<AppAction> {
	return Heading(H3, content);
}
