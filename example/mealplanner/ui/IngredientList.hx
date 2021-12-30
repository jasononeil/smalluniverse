package mealplanner.ui;

import mealplanner.App.appRouter;
import mealplanner.AppAction;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.ListView;
import mealplanner.ui.Heading;

function IngredientList(
	name:String,
	ingredients:Array<{ingredient:String, ticked:Bool, info:Null<String>}>,
	?extraItems:Html<AppAction>
) {
	return [
		css(CompileTime.readFile("mealplanner/ui/IngredientList.css")),
		section([
			className("IngredientList")
		], [
			Heading3(name),
			ListView(ingredients.map(i -> {
				final info = i.info;
				return ListItemLink(label([], [checkbox([
					checked(i.ticked),
					className("IngredientList__Checkbox")
				]), i.ingredient, info != null ? span([
					className("IngredientList__Info")
					], info) : []]), appRouter.uriForIngredientPage({
					ingredient: i.ingredient
					}));
			}).concat(extraItems != null ? [extraItems] : []))
		])
	];
}
