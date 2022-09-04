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

	actionTrigger
			.asSignal()
			.handle(action -> postAction(action, router, renderer));
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
function renderPage(
	router:Router,
	renderer:SnabbdomRenderer,
	pageDataJson:String
) {
	switch router.uriToRoute(document.location.pathname) {
		case Some(Page(page, params)):
			final pageData = page.dataEncoder.decode(pageDataJson);
			final html = page.render(pageData);
			renderer.update(html);
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

private function postAction<Action>(
	action:Action,
	router:Router,
	renderer:SnabbdomRenderer
) {
	// Get the JSON encoder.
	// This is a bit gross. It might be better to somehow set postAction up with whatever encoder is known from the current routing event.
	final actionEncoder = switch router.uriToRoute(document.location.pathname) {
		case Some(Page(page, params)):
			page.actionEncoder;
		case None:
			// TODO: handle Not Found errors.
			null;
	}
	if (actionEncoder == null) {
		throw "Violation: we couldn't find a page for the current route, despite an action being triggered (presumably from a page)";
	}

	window.fetch("" + document.location, {
		method: "POST",
		body: actionEncoder.encode(action),
		headers: {
			"Content-Type": "application/json",
			"Accept": "application/json"
		}
	}).then((result) -> {
		result.text().then(pageDataJson -> {
			// If the action resulted in a command that requested a redirect when successful, then:
			// - The server will issue a 302 redirect
			// - The browser will follow this redirect (again, requesting a JSON response)
			// - The server will respond with the PageData for the new page.
			// In the client, we can check for this redirect, and update our browser URL to match.
			// The Router will then locate the page we're redirecting to, and we already have the data to render it.
			// See CommonServerFunctions.renderResponse()
			if (result.redirected) {
				window.history.pushState({}, "", result.url);
			}
			renderPage(router, renderer, pageDataJson);
		});
	});
}
