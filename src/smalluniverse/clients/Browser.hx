package smalluniverse.clients;

import js.html.PopStateEvent;
import smalluniverse.renderers.SnabbdomRenderer;
import haxe.Json;
import smalluniverse.SmallUniverse;
import js.Browser.document;
import js.Browser.window;

using tink.CoreApi;

private var changeUrlTrigger = new SignalTrigger<Noise>();

function init(router:Router) {
	final container = document.getElementById("__SmallUniverse__Container");
	final renderer = new SnabbdomRenderer();

	renderer.init(container);

	performInitialRender(router, renderer);

	window.addEventListener("popstate", (e:PopStateEvent) -> {
		changeUrlTrigger.trigger(Noise);
	});

	changeUrlTrigger.asSignal().handle(() -> handleUrlChange(router, renderer));
}

/**
	Do an initial render with the same data the server sent us.
	This hydrates the page (adds event listeners etc).
**/
function performInitialRender(router:Router, renderer:SnabbdomRenderer) {
	final pageDataScript = document.getElementById("__SmallUniverse__PageData");
	final pageData = Json.parse(pageDataScript.innerText);
	renderPage(router, renderer, pageData);
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
		result.json().then(json -> {
			renderPage(router, renderer, json);
		});
	});
}

/**
	Use the router to find the current page and render it.
**/
function renderPage(router:Router, renderer:SnabbdomRenderer, pageData:Dynamic) {
	switch router.uriToRoute(document.location.pathname) {
		case Some(route):
			switch route.page {
				case Page(view, _api):
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
function postAction<Action>(action:Action) {
	final fetchResult = window.fetch("" + document.location, {
		method: "POST",
		// TODO: we should be using tink.Json for compile safe encoding/decoding
		body: Json.stringify(action),
		headers: {
			"Content-Type": "application/json",
			"Accept": "application/json"
		}
	}).then((result) -> {
		result.json().then(json -> {
			// We will need to refactor this function to be somewhere where we have access to rerender
			// We don't have access to `router` or `renderer` in this static function.
			// renderPage(router, renderer, json);
		});
	});
}