package smalluniverse.clients;

import haxe.Json;
import smalluniverse.SmallUniverse;
import js.Browser.document;

function init(router:Router) {
	final pageDataScript = document.getElementById("__SmallUniverse__PageData");
	final pageData = Json.parse(pageDataScript.innerText);
	switch router.uriToRoute(document.location.pathname) {
		case Some(route):
			trace('Found a route!', route.page, route.params, pageData);
		case None:
	}
}
