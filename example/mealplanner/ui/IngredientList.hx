package mealplanner.ui;

import js.html.InputElement;
import mealplanner.App.appRouter;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.ListView;
import mealplanner.ui.Heading;
import mealplanner.ui.Paragraph;

// TODO: consider if this component still makes sense. There's now an IngredientList for a shopping page (with a checkbox),
// and a meals page (no checkbox), and they're "info" strings are different. Trying to unify them might not be worth it.
function IngredientList<Action>(name:String, ingredients:Array<{
	ingredient:String,
	ticked:Bool,
	info:Null<String>,
	onChange:Bool->Action
}>, ?extraItems:Html<Action>) {
	final countTotal = ingredients.length;
	final countUnticked = ingredients.filter(i -> !i.ticked).length;
	return [
		css(CompileTime.readFile("mealplanner/ui/IngredientList.css")),
		section([
			className("IngredientList")
		], [
			Heading3(name),
			Paragraph('$countUnticked / $countTotal items remaining'),
			ListView(ingredients.map(i -> {
				final info = i.info;
				final ingredientUrl = appRouter.uriForIngredientPage({
					ingredient: i.ingredient
				});
				final infoSpan:Html<Action> = info != null ? span([
					className("IngredientList__Info")
				], info) : "";
				final itemContent = label(
					[className("IngredientList__Label")],
					[
						checkbox([
							on("change", (e) -> {
								final inputElement:Null<InputElement> = Std.downcast(
									e.currentTarget,
									InputElement
								);
								final value = inputElement != null ? inputElement.checked : false;
								return Some(i.onChange(value));
							}),
							checked(i.ticked),
							className("IngredientList__Checkbox"),
						]),
						i.ingredient,
						infoSpan
					]
				);
				// This used to be ListItemLink with ingredientUrl
				return ListItem(itemContent);
			}).concat(extraItems != null ? [extraItems] : []))
		])
	];
}
