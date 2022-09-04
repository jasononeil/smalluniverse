package smalluniverse.servers;

import smalluniverse.SmallUniverse;
import smalluniverse.servers.common.CommonServerFunctions;
import js.Node;
import js.node.Path;
import js.node.http.ServerResponse;
import js.node.http.IncomingMessage;
import js.node.Http;
import js.node.Fs;

using Lambda;
using StringTools;
using tink.CoreApi;

function start(
	router:Router,
	orchestrator:Orchestrator,
	host:String = "0.0.0.0",
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
	trace('Request: ${req.method} ${req.url}');

	if (req.url == "/js/client.bundle.js") {
		return loadClientScript(res);
	}

	final contentType = req.headers["accept"];
	final responseFormat =
		contentType != null &&
		contentType.startsWith("application/json") ? Json : Html;

	handleSmallUniverseRequest({
		url: req.url,
		isAction: req.method == "POST",
		responseFormat: responseFormat,
		readRequestBody: () -> readRequestBody(req),
		printResponse: (
			type,
			status,
			content
		) -> printResponse(res, type, status, content),
		redirectResponse: (url) -> redirectResponse(res, url),
		router: router,
		orchestrator: orchestrator,
	});
}

function readRequestBody(req:IncomingMessage):Promise<String> {
	final trigger = Promise.trigger();
	final body = new StringBuf();
	req.on("data", chunk -> body.add(chunk));
	req.on("end", () -> trigger.resolve(body.toString()));
	return trigger.asPromise();
}

function printResponse(
	res:ServerResponse,
	contentType:ResponseFormat,
	status:Int,
	content:String
) {
	res.statusCode = status;
	res.setHeader("Content-Type", switch contentType {
		case Html: "text/html; charset=UTF-8";
		case Json: "application/json; charset=UTF-8";
	});
	res.write(content);
	res.end();
}

function redirectResponse(res:ServerResponse, url:String) {
	res.setHeader("Location", url);
	res.statusCode = 301;
	res.end();
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
