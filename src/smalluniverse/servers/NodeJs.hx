package smalluniverse.servers;

import js.node.http.ServerResponse;
import js.node.http.IncomingMessage;
import js.node.Http;
import smalluniverse.SmallUniverse.Router;
import smalluniverse.renderers.HtmlStringRenderer;

function start(router:Router, host:String = "localhost", port:Int = 4723) {
	final server = Http.createServer(handleRequest.bind(router));
	trace('Listening on http://$host:$port');
	server.listen(port, host);
}

function handleRequest(router:Router, req:IncomingMessage, res:ServerResponse) {
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
						final viewHtml = stringifyHtml(view.render(pageData));
						res.setHeader("Content-Type", "text/html");
						res.write(viewHtml);
						res.statusCode = 200;
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
