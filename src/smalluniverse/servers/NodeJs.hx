package smalluniverse.servers;

import js.node.Require;
import haxe.Json;
import js.Node;
import js.node.Path;
import js.node.http.ServerResponse;
import js.node.http.IncomingMessage;
import js.node.Http;
import js.node.Fs;
import smalluniverse.SmallUniverse.Router;
import smalluniverse.renderers.HtmlStringRenderer;

using Lambda;
using StringTools;

function start(router:Router, host:String = "localhost", port:Int = 4723) {
	final server = Http.createServer(handleRequest.bind(router));
	trace('Listening on http://$host:$port');
	server.listen(port, host);
}

function handleRequest(router:Router, req:IncomingMessage, res:ServerResponse) {
	if (req.url == "/js/client.bundle.js") {
		return loadClientScript(res);
	}

	// This could use a big old tidy up.
	// And it also probably needs to handle async getPageData() calls.
	// And probably lazy loading (with dependency injection?) for out API objects.
	// And wrapping the view in a HTML template.
	try {
		switch router.uriToRoute(req.url) {
			case Some(route):
				switch route.page {
					case Page(view, api):
						final pageData = api.getPageData(route.params);
						// TODO: use tink.Json instead
						final pageDataJson = Json.stringify(pageData);
						switch (req.headers["accept"]) {
							case "application/json":
								// This is a request from our client JS. Return the data.
								res.setHeader("Content-Type", "application/json; charset=UTF-8");
								res.write(pageDataJson);
								res.statusCode = 200;
							default:
								// Render the page as HTML
								final viewHtml = stringifyHtml(view.render(pageData));
								res.setHeader("Content-Type", "text/html; charset=UTF-8");
								res.write(wrapHtml(viewHtml, pageDataJson));
								res.statusCode = 200;
						}
				}
			case None:
				res.write("page not found");
				res.statusCode = 404;
		}
		res.end();
	} catch (err) {
		res.write('Internal server error: $err');
		res.statusCode = 501;
		res.end();
	}
}

function wrapHtml(bodyContent:String, pageDataJson:String) {
	return CompileTime.interpolateFile("smalluniverse/template.html");
}

function loadClientScript(res:ServerResponse) {
	final clientJsPath = Path.join(Node.__dirname, "client.bundle.js");
	Fs.readFile(clientJsPath, "utf-8", (err, content) -> {
		res.setHeader("Content-Type", "application/javascript");
		res.write(content);
		res.statusCode = 200;
		res.end();
	});
}
