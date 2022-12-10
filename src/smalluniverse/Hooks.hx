package smalluniverse;

import smalluniverse.SmallUniverse;
import haxe.ds.Option;

function onInit<Action>(
	callback:InitHookArgs<Action>->Option<Void->Void>
):HtmlAttribute<Action> {
	return Hook(Init(callback));
}

function onInsert<Action>(
	callback:InsertHookArgs<Action>->Void
):HtmlAttribute<Action> {
	return Hook(Insert(callback));
}

function onRemove<Action>(
	callback:RemoveHookArgs<Action>->Void
):HtmlAttribute<Action> {
	return Hook(Remove(callback));
}

function onDestroy<Action>(
	callback:DestroyHookArgs<Action>->Void
):HtmlAttribute<Action> {
	return Hook(Destroy(callback));
}
