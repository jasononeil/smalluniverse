package mealplanner.ui;

import js.Browser;
import js.html.InputElement;
import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import mealplanner.ui.ListView;
import mealplanner.ui.Heading;
import mealplanner.ui.Paragraph;
import mealplanner.ui.ActionMenu;

function MealItemList<Action>(name:String, ingredients:Array<{
	ingredient:String,
	ticked:Bool,
	onTickedChange:Bool->Action,
	onEditName:String->Action,
	onDelete:Action,
}>, onNewItem:String->Action) {
	final rows = ingredients.map(i -> {
		final itemLabel = label([className("IngredientList__Label")], [
			checkbox([
				on("change", (e) -> {
					final inputElement:Null<InputElement> = Std.downcast(
						e.currentTarget,
						InputElement
					);
					final value = inputElement != null ? inputElement.checked : false;
					return Some(i.onTickedChange(value));
				}),
				checked(i.ticked),
				className("IngredientList__Checkbox"),
			]),
			i.ingredient
		]);
		final editItemSelect = ActionMenu("⋯", ["Edit" => () -> {
			final newName = Browser.window.prompt(
				"Edit ingredient name",
				i.ingredient
			);
			if (newName == null || newName == "") {
				return None;
			}
			return Some(i.onEditName(newName));
		}, "Delete" => () -> {
			final deletionConfirmed = Browser.window.confirm(
				'Delete ingredient ${i.ingredient}'
			);
			return deletionConfirmed ? Some(i.onDelete) : None;
		}]);
		return ListItem(div([className("IngredientList__FlexRow")], [
			itemLabel,
			editItemSelect
		]));
	});
	rows.push(
		ListItemInput(
			"New Ingredient",
			"",
			text -> text != "" ? Some(onNewItem(text)) : None
		)
	);
	final countTotal = ingredients.length;
	final countUnticked = ingredients.filter(i -> !i.ticked).length;
	return GenericItemList({
		name: name,
		ingredients: rows,
		countTotal: countTotal,
		countUnticked: countUnticked
	});
}

function ShoppingList<Action>(name:String, ingredients:Array<{
	ingredient:String,
	ticked:Bool,
	info:String,
	onTickedChange:Bool->Action,
}>) {
	final rows = ingredients.map(i -> {
		final info = i.info;
		final infoSpan:Html<Action> = info != null ? span([
			className("IngredientList__Info")
		], info) : "";
		final itemLabel = label([className("IngredientList__Label")], [
			checkbox([
				on("change", (e) -> {
					final inputElement:Null<InputElement> = Std.downcast(
						e.currentTarget,
						InputElement
					);
					final value = inputElement != null ? inputElement.checked : false;
					return Some(i.onTickedChange(value));
				}),
				checked(i.ticked),
				className("IngredientList__Checkbox"),
			]),
			i.ingredient,
			infoSpan
		]);
		return ListItem(div([className("IngredientList__FlexRow")], itemLabel));
	});
	final countTotal = ingredients.length;
	final countUnticked = ingredients.filter(i -> !i.ticked).length;
	return GenericItemList({
		name: name,
		ingredients: rows,
		countTotal: countTotal,
		countUnticked: countUnticked
	});
}

function GenericItemList<Action>(data:{
	name:String,
	ingredients:Array<Html<Action>>,
	countTotal:Int,
	countUnticked:Int
}) {
	return [
		css(CompileTime.readFile("mealplanner/ui/IngredientList.css")),
		section([
			className("IngredientList")
		], [
			Heading3(data.name),
			Paragraph(
				'${data.countUnticked} / ${data.countTotal} items remaining'
			),
			ListView(data.ingredients)
		])
	];
}
