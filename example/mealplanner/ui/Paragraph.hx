package mealplanner.ui;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;

function Paragraph<T>(content:Html<T>):Html<T> {
	return [
		css(CompileTime.readFile("mealplanner/ui/Paragraph.css")),
		element('p', [
			className("Paragraph")
		], content)
	];
}
