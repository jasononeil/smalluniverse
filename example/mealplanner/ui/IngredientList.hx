package mealplanner.ui;

import mealplanner.App.appRouter;
import mealplanner.AppAction;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.ListView;
import mealplanner.ui.Heading;

// TODO: consider if this component still makes sense. There's now an IngredientList for a shopping page (with a checkbox),
// and a meals page (no checkbox), and they're "info" strings are different. Trying to unify them might not be worth it.
function IngredientList<Action>(
	name:String,
	ingredients:Array<{ingredient:String, ticked:Null<Bool>, info:Null<String>}>,
	?extraItems:Html<Action>
) {
	return [
		css(CompileTime.readFile("mealplanner/ui/IngredientList.css")),
		section([
			className("IngredientList")
		], [
			Heading3(name),
			ListView(ingredients.map(i -> {
				final info = i.info;
				final ingredientUrl = appRouter.uriForIngredientPage({
					ingredient: i.ingredient
				});
				final infoSpan:Html<Action> = info != null ? span([
					className("IngredientList__Info")
				], info) : "";
				var itemContent:Html<Action> = [i.ingredient, infoSpan];
				if (i.ticked != null) {
					// Render a checkbox and wrap it all in a label.
					itemContent = label([], [checkbox([
						checked(i.ticked),
						className("IngredientList__Checkbox"),
					]), itemContent]);
				}
				return ListItemLink(itemContent, ingredientUrl);
			}).concat(extraItems != null ? [extraItems] : []))
		])
	];
}
