package smalluniverse.servers;

import smalluniverse.SmallUniverse;
import js.Node;
import js.node.Path;
import js.node.http.ServerResponse;
import js.node.http.IncomingMessage;
import js.node.Http;
import js.node.Fs;
import smalluniverse.renderers.HtmlStringRenderer;

using Lambda;
using StringTools;
using tink.CoreApi;

function start(
	router:Router,
	orchestrator:Orchestrator,
	host:String = "localhost",
	port:Int = 4723
) {
	listenForNodeEvents();
	orchestrator.setup().handle(_ -> {
		Node.process.on('exit', (code) -> {
			orchestrator.teardown();
		});
		final server = Http.createServer(
			handleRequest.bind(router, orchestrator)
		);
		trace('Listening on http://$host:$port');
		server.listen(port, host);
	});
}

function listenForNodeEvents() {
	Node.process.on('uncaughtException', (err) -> {
		trace('Uncaught exception: ' + err);
	});
	Node.process.on('unhandledRejection', (reason, promise) -> {
		trace('Unhandled rejection', reason, promise);
		Node.process.exit(1);
	});
	Node.process.on('SIGINT', (code) -> {
		trace("SIGINT received, exiting process now");
		Node.process.exit(1);
	});
}

function handleRequest(
	router:Router,
	orchestrator:Orchestrator,
	req:IncomingMessage,
	res:ServerResponse
) {
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
					case Page(view, api, actionEncoder, pageDataEncoder):
						handlePage(
							req,
							res,
							orchestrator,
							route,
							api,
							view,
							actionEncoder,
							pageDataEncoder
						);
				}
			case None:
				printError(res, new Error(NotFound, "Page not found"));
		}
	} catch (err) {
		printError(
			res,
			new Error(InternalError, 'Internal server error: $err')
		);
	}
}

// This function signature would be way less ugly if `Page` was an object and not an enum instance, then we could pass that in.
function handlePage<
	Action,
	PageParams,
	PageData
	>(
		req:IncomingMessage,
		res:ServerResponse,
		orchestrator:Orchestrator,
		route:ResolvedRoute<PageParams>,
		api:PageApi<Action, PageParams, PageData>,
		view:PageView<Action, PageData>,
		actionEncoder:IJsonEncoder<Action>,
		pageDataEncoder:IJsonEncoder<PageData>
	):Promise<Noise> {
		return Promise.NOISE.next((_) -> {
			// Handle POST Action if there is one.
			final jsonRequest = req.headers["content-type"] == "application/json";
			final isAction = req.method == "POST" && jsonRequest;
			if (!isAction) {
				return Noise;
			}
			return readRequestBody(req).next(body -> {
				final action = actionEncoder.decode(body);
				final command = api.actionToCommand(route.params, action);
				return orchestrator.handleCommand(command);
			});
		}).next((_) -> {
			// Get Page Data
			return api.getPageData(route.params);
		}).next((pageData) -> {
			// Render response
			final pageDataJson = pageDataEncoder.encode(pageData);
			switch (req.headers["accept"]) {
				case "application/json":
					// This is a request from our client JS. Return the data.
					res.statusCode = 200;
					res.setHeader(
						"Content-Type",
						"application/json; charset=UTF-8"
					);
					res.write(pageDataJson);
					res.end();
				default:
					// Render the page as HTML
					final viewHtml = stringifyHtml(view.render(pageData));
					final html = wrapHtml(viewHtml, pageDataJson);
					res.statusCode = 200;
					res.setHeader("Content-Type", "text/html; charset=UTF-8");
					res.write(html);
					res.end();
			}
			return Noise;
		}).recover(err -> {
			printError(res, err);
			return Noise;
		}).eager();
}

function printError(res:ServerResponse, err:Error) {
	res.write(err.toString());
	res.statusCode = err.code;
	res.end();
}

function readRequestBody(req:IncomingMessage):Promise<String> {
	final trigger = Promise.trigger();
	final body = new StringBuf();
	req.on("data", chunk -> body.add(chunk));
	req.on("end", () -> trigger.resolve(body.toString()));
	return trigger.asPromise();
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
