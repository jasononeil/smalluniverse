package smalluniverse;

import smalluniverse.SmallUniverse;

function onInit<Action>(
	callback:InitHookArgs<Action>->Void
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

/**
	Cause a side effect when the element is created, with the opportunity to clean it up when the element is removed.
**/
function onInitAndDestroy<Action>(
	callbackThatReturnsCleanup:InitHookArgs<Action>->(DestroyHookArgs<Action>->
		Void)
):HtmlAttribute<Action> {
	var cleanup = (args:DestroyHookArgs<Action>) -> {};
	return Multiple([
		Hook(Init(args -> cleanup = callbackThatReturnsCleanup(args))),
		Hook(Destroy(args -> cleanup(args)))
	]);
}
