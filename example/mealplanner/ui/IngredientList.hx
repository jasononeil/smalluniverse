package mealplanner.ui;

import smalluniverse.DOM;

function IngredientList(name:String, ingredients:Array<{ingredient:String, ticked:Bool}>) {
	return [
		h2([], name),
		ul([], [
			ingredients.map(i -> li([], [label([], [checkbox([checked(i.ticked)]), i.ingredient])]))
		])
	];
}
