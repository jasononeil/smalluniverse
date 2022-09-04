package smalluniverse.servers.common;

import smalluniverse.SmallUniverse;
import smalluniverse.renderers.HtmlStringRenderer;

using Lambda;
using StringTools;
using tink.CoreApi;

/**
	The content of the response to be sent to the client.
**/
enum ResponseContent<PageData> {
	/** Return page data, either as JSON or rendered HTML. **/
	ResponsePageData(page:Page<Any, Any, PageData>, pageData:PageData);

	/** Redirect the client browser. This will either redirect a HTML response (and so the browser tab) or a JSON response (in which case our client will need to detect the redirect and update the browser tab to match). **/
	ResponseRedirect(url:String);

	/** Display an error, either printing as HTML, or a JSON response the client will use to display the error. **/
	ResponseError(error:Error);
}

/**
	Whether the response should be sent as HTML or JSON.
**/
enum ResponseFormat {
	Html;
	Json;
}

/**
	A function that can print a string to the response. It should:
	- Set the status code correctly
	- Set appropriate Content-Type headers for either JSON or HTML
	- Write the body content
**/
typedef PrintFunction = (
	format:ResponseFormat,
	status:Int,
	body:String
) -> Void;

/**
	A function that can set a HTTP redirect on the response. It should:
	- Set a 301 status.
	- Set a `Location` header pointing to the requested URL.
**/
typedef RedirectFunction = (url:String) -> Void;

/**
	Handle a request for a SmallUniverse application.

	This will:
	- Use the URL to identify the correct page, or give a 404 error.
	- If a POST request, read the request body as a PageAction and handle the resulting Commands.
	- Query up-to-date PageData for the current page
	- Render the result as either HTML (a fully rendered page) or JSON (the serialized PageData)
**/
function handleSmallUniverseRequest(props:{
	url:String,
	isAction:Bool,
	responseFormat:ResponseFormat,
	readRequestBody:() -> Promise<String>,
	printResponse:PrintFunction,
	redirectResponse:RedirectFunction,
	router:Router,
	orchestrator:Orchestrator,
}):Promise<Noise> {
	final responseContentPromise = try {
		switch props.router.uriToRoute(props.url) {
			case Some(Page(page, params)):
				handleRequestForPage({
					isAction: props.isAction,
					responseFormat: props.responseFormat,
					readRequestBody: props.readRequestBody,
					orchestrator: props.orchestrator,
					page: page,
					params: params,
				});
			case None:
				Promise.resolve(
					ResponseError(new Error(NotFound, "Page not found"))
				);
		}
	} catch (err) {
		Promise.resolve(
			ResponseError(
				new Error(InternalError, 'Internal server error: $err')
			)
		);
	}

	responseContentPromise.handle(outcome -> switch outcome {
		case Success(responseContent):
			renderResponse(
				props.printResponse,
				props.redirectResponse,
				props.responseFormat,
				responseContent
			);
		case Failure(err):
			renderResponse(
				props.printResponse,
				props.redirectResponse,
				props.responseFormat,
				ResponseError(
					new Error(InternalError, 'Internal server error: $err')
				)
			);
	});

	return responseContentPromise.noise();
}

/**
	For a known page, handle the request, meaning:

	- If the request is a POST request, process the Action / Command, including handling any redirects or errors.
	- Load the PageData for the current page
	- Return a Promise for the appropriate ResponseContent (page data, redirect, or an error).
**/
private function handleRequestForPage<Action, PageParams, PageData>(props:{
	isAction:Bool,
	responseFormat:ResponseFormat,
	readRequestBody:() -> Promise<String>,
	orchestrator:Orchestrator,
	page:Page<Action, PageParams, PageData>,
	params:PageParams
}):Promise<ResponseContent<Any>> {
	final pageApi = props.orchestrator.apiForPage(props.page);
	if (props.isAction) {
		if (props.responseFormat.match(Html)) {
			final expectedJsonError = new Error(
				BadRequest,
				"A POST request must use the application/json Content Type"
			);
			return ResponseError(expectedJsonError);
		}
		return props
				.readRequestBody()
				.next(
				reqBody -> doCommand(
					reqBody,
					props.orchestrator,
					props.page,
					pageApi,
					props.params
				)
			);
	}
	return doQuery(props.page, pageApi, props.params);
}

/**
	Process a POST request body into a PageAction, ask the page to turn it into a Command, and attempt to handle the Command.

	If successful, and the Command did not request a redirect, then this will continue on to call `doQuery()`.
			  
	(Note: this is baking in the assumption that a POST request to send a command should include updated PageData in its response.
	If we switch to a more asynchronous flow in future (eg pushing new data over websockets) this assumption may break.)
**/
private function doCommand<
	Action
	,
	PageParams
	,
	PageData
	>(
		reqBody:String,
		orchestrator:Orchestrator,
		page:Page<Action, PageParams, PageData>,
		pageApi:PageApi<Action, PageParams, PageData>,
		params:PageParams
	):Promise<ResponseContent<Any>> {
		final action = page.actionEncoder.decode(reqBody);
		trace('Received Action', action);
		return pageApi.actionToCommand(params, action).next(command -> {
			trace('Command', command.toString());
			orchestrator.handleCommand(command);
			switch command.postCommand {
				case UpdatePageOnClient:
					return doQuery(page, pageApi, params);
				case RedirectClientTo(url):
					return ResponseRedirect(url);
			}
		});
}

/**
	Query the data for a given page, and return a Promise for the response content.
**/
private function doQuery<
	Action
	,
	PageParams
	,
	PageData
	>(
		page:Page<Action, PageParams, PageData>,
		pageApi:PageApi<Action, PageParams, PageData>,
		params:PageParams
	):Promise<ResponseContent<Any>> {
		return pageApi.getPageData(params).next((pageData) -> {
			return ResponsePageData(page, pageData);
		});
}

/**
	A function to write the response (page data, error or redirect) in the expected format (HTML or JSON).
**/
private function renderResponse(
	printResponse:PrintFunction,
	redirectResponse:RedirectFunction,
	responseFormat:ResponseFormat,
	responseContent:ResponseContent<Any>
):Void {
	switch (responseFormat) {
		case Json:
			switch responseContent {
				case ResponsePageData(page, pageData):
					final pageDataJson = page.dataEncoder.encode(pageData);
					printResponse(Json, 200, pageDataJson);
				case ResponseRedirect(url):
					// Note: the client browser will automatically redirect this fetch call.
					// That means the client will see a (hopefully) `200` response with the JSON data for the page we're redirecting too.
					// In the client, we need to check the fetch response for `res.redirected=true`, and use the `res.url` to display the corect page.
					redirectResponse(url);
				case ResponseError(error):
					final errorJson = tink.Json.stringify({
						code: error.code,
						message: error.message,
					});
					printResponse(Json, error.code, errorJson);
			}
		case Html:
			switch responseContent {
				case ResponsePageData(page, pageData):
					final viewHtml = stringifyHtml(page.render(pageData));
					final pageDataJson = page.dataEncoder.encode(pageData);
					final htmlContent = wrapHtml(viewHtml, pageDataJson);
					printResponse(Html, 200, htmlContent);
				case ResponseRedirect(url):
					redirectResponse(url);
				case ResponseError(error):
					printResponse(Html, error.code, error.toString());
			}
	}
}

/** Wrap the body content and the page data into a HTML template. **/
private function wrapHtml(bodyContent:String, pageDataJson:String) {
	return CompileTime.interpolateFile("smalluniverse/template.html");
}
