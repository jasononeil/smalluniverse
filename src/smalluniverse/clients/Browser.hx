package smalluniverse.clients;

import js.html.PopStateEvent;
import smalluniverse.renderers.SnabbdomRenderer;
import haxe.Json;
import smalluniverse.SmallUniverse;
import js.Browser.document;
import js.Browser.window;

using tink.CoreApi;

private var changeUrlTrigger = new SignalTrigger<Noise>();
private var actionTrigger = new SignalTrigger<Any>();

function init(router:Router) {
	final container = document.getElementById("__SmallUniverse__Container");
	final renderer = new SnabbdomRenderer();

	renderer.init(container);

	performInitialRender(router, renderer);

	window.addEventListener("popstate", (e:PopStateEvent) -> {
		changeUrlTrigger.trigger(Noise);
	});

	changeUrlTrigger.asSignal().handle(() -> handleUrlChange(router, renderer));

	actionTrigger.asSignal().handle(action -> postAction(action, router, renderer));
}

/**
	Do an initial render with the same data the server sent us.
	This hydrates the page (adds event listeners etc).
**/
function performInitialRender(router:Router, renderer:SnabbdomRenderer) {
	final pageDataScript = document.getElementById("__SmallUniverse__PageData");
	final pageDataJson = pageDataScript.innerText;
	renderPage(router, renderer, pageDataJson);
}

/**
	Respond to URL changes by fetch updated pageData and re-rendering.
**/
function handleUrlChange(router:Router, renderer:SnabbdomRenderer) {
	window.fetch("" + document.location, {
		headers: {
			"Accept": "application/json"
		}
	}).then((result) -> {
		result.text().then(pageDataJson -> {
			renderPage(router, renderer, pageDataJson);
		});
	});
}

/**
	Use the router to find the current page and render it.
**/
function renderPage(router:Router, renderer:SnabbdomRenderer, pageDataJson:String) {
	switch router.uriToRoute(document.location.pathname) {
		case Some(route):
			switch route.page {
				case Page(view, _api, _actionEncoder, pageDataEncoder):
					final pageData = pageDataEncoder.decode(pageDataJson);
					final html = view.render(pageData);
					renderer.update(html);
			}
		case None:
			// TODO: handle Not Found errors.
	}
}

/**
	Trigger a URL change using the history API, and render the new page.
**/
function triggerNavigation(url:String) {
	window.history.pushState({}, "", url);
	changeUrlTrigger.trigger(Noise);
}

/**
	Post an action to the API.
	For internal use only - you should be posting actions by triggering events from the DOM and trusting the framework to call this function.
**/
function triggerAction<Action>(action:Action) {
	actionTrigger.trigger(action);
}

private function postAction<Action>(action:Action, router:Router, renderer:SnabbdomRenderer) {
	// Get the JSON encoder.
	// This is a bit gross. It might be better to somehow set postAction up with whatever encoder is known from the current routing event.
	final actionEncoder = switch router.uriToRoute(document.location.pathname) {
		case Some(route):
			switch route.page {
				case Page(_view, _api, actionEncoder, _pageDataEncoder):
					actionEncoder;
			}
		case None:
			// TODO: handle Not Found errors.
			null;
	}
	if (actionEncoder == null) {
		throw "Violation: we couldn't find a page for the current route, despite an action being triggered (presumably from a page)";
	}

	window.fetch("" + document.location, {
		method: "POST",
		// TODO: we should be using tink.Json for compile safe encoding/decoding
		body: actionEncoder.encode(action),
		headers: {
			"Content-Type": "application/json",
			"Accept": "application/json"
		}
	}).then((result) -> {
		result.text().then(pageDataJson -> {
			renderPage(router, renderer, pageDataJson);
		});
	});
}
