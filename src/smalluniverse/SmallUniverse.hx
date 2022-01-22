package smalluniverse;

import js.html.Event;

using tink.CoreApi;

/**
	Routes and Pages
	================

	Routing and Page views can be executed on both the client (as a Single Page Application / SPA) and the server (using Server Side Rendering / SSR).

	You could consider these the "Front End" of your application, they're the parts a user interacts with.
**/
/**
	A Router takes a URI and returns a `ResolvedRoute` (a known page to display) if one exists.
**/
interface Router {
	function uriToRoute(uri:String):Option<ResolvedRoute<Dynamic>>;
}

/**
	A known route, including the parameters passed to it, and the page that should be displayed.
**/
enum ResolvedRoute<PageParams> {
	Page(page:Page<Dynamic, PageParams, Dynamic>, params:PageParams);
	// In future we might have other types for non-page server routes (eg RSS, iCal, Rest APIs etc)
}

/**
	A Page to be displayed in the users browser.
**/
interface Page<Action, PageParams, PageData> {
	/**
		A type-safe JSON encoder used to encode our actions for transferring to our PageAPI.

		Usually `public var actionEncoder = new JsonEncoder<Action>()` is sufficient.
		This will use macros to generate a type safe decoder for your Action.
	**/
	var actionEncoder:IJsonEncoder<Action>;

	/**
		A type-safe JSON encoder used to encode our page data for transferring from our PageAPI.

		Usually `public var dataEncoder = new JsonEncoder<PageData>()` is sufficient.
		This will use macros to generate a type safe decoder for your PageData.
	**/
	var dataEncoder:IJsonEncoder<PageData>;

	/**
		The view function for rendering a page.
		You can compose your page from multiple components and functions but each page has one root-level `render()` function.	
		The data passed to it is the data received from the `PageApi.getPageData()` function.
	**/
	function render(data:PageData):Html<Action>;
}

/**
	A PageApi is the back-end API required for displaying a page and handling its actions and updates.

	Each Page should have exactly one PageApi, and the PageApi can interact with multiple `EventSource` or `Projection` services.
**/
interface PageApi<Action, PageParams, PageData> {
	/** A reference to the Page class this API is tightly coupled to. **/
	var relatedPage(default, null):Class<Page<Action, PageParams, PageData>>;

	/** Load data for the given page. **/
	function getPageData(pageParams:PageParams):Promise<PageData>;

	/** Convert a page Action into the relevant Command for our Event Stores.**/
	function actionToCommand(
		pageParams:PageParams,
		action:Action
	):Promise<Command<Any>>;

	// In future we could do something like this for websockets
	// var subscriptions:Array<{ projection: Projection<T>, shouldUpdate: T->Bool }>
}

/**
	Will create an `IJsonEncoder<T>` instance with encode/decode function for the given type.

	Uses tink_json under the hood.
**/
@:genericBuild(smalluniverse.macros.JsonEncoderMacros.build())
class JsonEncoder<T> {}

/**
	A type safe JSON encoder/decoder for a given type.

	We use JSON for passing data between the client and server.
	We cannot use simple JSON parsing, as we rely on type-safe parsers that are aware of Haxe specific types like enums (generally using tink_json via `JsonEncoder`).
**/
interface IJsonEncoder<T> {
	public function encode(value:T):String;
	public function decode(json:String):T;
}

/**
	Back End Data Services
	======================

	Our back end data is stored in various kinds of services:

	- EventStore (the storage mechanism for storing our streams of events)
	- EventSource (the source-of-truth model for a particular data domain, responsible for accepting/rejecting new events)
	- Projection (a particular view of the data built up by processing our events one at a time)
	- PageApi (these run on the server, but are conceptually part of the "front end". They interact with EventSource and Projection services to load data and handle actions).

	For the architecture of our backend services (Event Source, Projection, Page Api) my design goals are:

	- Have an API that makes you think about the flow of data, not the communication of services.
	- Sufficiently decoupled that a page can interact with multiple services, and a service can serve multiple pages.
	- Sufficiently abstracted to allow the architecture to be deployed:
		- As a long lived NodeJS process (for local development, and easy VPS hosting)
		- As serverless functions (all stream processing happens during the request, also good for PHP)
		- As a multi-service architecture where each service can scale independently and they communicate across the network.

	I don't intend to offer all of this up front, but want to design the API so it will be possible if ever needed.
**/
/**
	A unique identifier for a specific event. 

	This could be a UUID or a Database ID, but is always typed as a String.
**/
abstract EventId(String) from String to String {}

/**
	An EventStore is for storing a stream of Events and recalling them in batches.

	The storage mechanism could be in-memory, a flat file, a database, a Kafka stream, or almost anything.
**/
interface EventStore<Event> {
	// TODO: think about if this interface is necessary. It's methods are pretty much identical to EventSource, but the purpose is different.

	/**
		Publish the event to a log.
	**/
	// It might be nice to track the event origin (eg Page(page,params,action) or Cli(command) or something...).
	function publish(event:Event):Promise<EventId>;

	function getLatestEvent():Promise<Option<EventId>>;
	function readEvents(
		numberToRead:Int,
		startingFrom:Option<EventId>
	):Promise<Array<{
		id:EventId,
		payload:Event
		}>>;
}

/**
	An EventSource is a "source of truth" service for a particular data domain.

	When a page attempts to create an event, it goes to this service.
	During `handleEvent` the service must record the event so that we can share it with other services.
	Usually it is easiest to use an `EventStore` for this under the hood.

	If you want to reject the event (because it has invalid data, or the user doesn't have permission to do it, etc), `handleEvent` should return a rejected promise.

	Note: an EventSource could contain its own projection based on its own data, to allow it to perform validation logic while handling new events.
	This is also known as a "Write Model".
**/
interface EventSource<Event> {
	/**
		Handle a new event - including validation logic, updating a write model if needed, and adding to the event log.
		If the event should be rejected, return a rejected promise.
	**/
	function handleEvent(event:Event):Promise<EventId>;

	/** Get the latest event ID, to compare against bookmarks in projections. **/
	function getLatestEvent():Promise<Option<EventId>>;

	/** Read pages of events. **/
	function readEvents(
		numberToRead:Int,
		startingFrom:Option<EventId>
	):Promise<Array<{
		id:EventId,
		payload:Event
		}>>;

	// Q: Should an EventSource have a ProjectionStatus?
	// In theory, it should never be processing a backlog - if an event isn't processed it doesn't yet exist.
	// One edge case might be when creating a new EventSource projection / write model for an existing event log.
	// For this use case, I guess you could create a new `EventSource` class over the same `EventLog` and transition from one to the other.
	// For now, I'm going to not have a "status" funtion on EventSource.
	// It will be worth thinking about how we can rebuild an EventSource model (or build a fresh one from an existing event log).
	// addEventsFromExisting(newEventSource<T>, existingEventStore<T>)
	// transposeEventsFromExisting(newEventSource<A>, existingEventStore<B>, transform:A->B)
}

/**
	A basic `EventSource` that stores events _as is_ in a given `EventStore`.

	No validation is performed, and no other data model is updated.
**/
class BasicEventSource<Event> implements EventSource<Event> {
	var store:EventStore<Event>;

	public function new(eventStore:EventStore<Event>) {
		this.store = eventStore;
	}

	public function handleEvent(event)
		return this.store.publish(event);

	public function getLatestEvent()
		return this.store.getLatestEvent();

	public function readEvents(numberToRead, startingFrom)
		return this.store.readEvents(numberToRead, startingFrom);
}

/**
	A Projection is a data model that is built up based on Events that have happened.

	It processes all the events from one or more event sources and saves data that can be used on pages.

	Generally, projections store the data in a way that is "optimised for fast reads" - stored in a structure close to how it is consumed on pages so that those pages can load without doing heavy processing.

	Often you might have multiple projections to display the same data in different ways.
	For example, the same stream of events about a task list could derive different views/projections: "Task List", "Task Completion History" and "Task Dashboard" etc.

	Note: this can also be a "reactor" that reacts to the events without necessarily building up a data model.
	For example, you might respond to a "SendInvitation" event by sending an email without needing to update a data model.

	Also known as "Read Model", "Query Model", "Reactor".
**/
interface Projection {
	/** Declare the event sources we are subscribing to, and how handle them. **/
	var subscriptions(default, never):Iterable<ProjectionSubscriptions<Any>>;
}

/**
	A ProjectionSubscription describes how a `Projection` subscribes to a particular `EventSource`.

	A projection can have multiple ProjectionSubscriptions.
**/
typedef ProjectionSubscriptions<Event> = {
	/** The name of the projection subscription, for use in logging. **/
	name:String,

	/** The event source we are subscribing to. **/
	source:Class<EventSource<Event>>,

	/** Get the `EventId` of the last successfully processed event. **/
	// TODO: consider if having "bookmarks" be part of the Orchestrator implementation makes sense so apps don't have to worry about it.
	getBookmark:Void->Promise<Option<EventId>>,

	/** Process an event. **/
	handler:{id:EventId, payload:Event}->Promise<ProjectionHandlerResult>,
}

/** 
	A status for how a projection handled an event.

	This is used to allow an `Orchestrator` to decide whether to continue processing new events, retry events, pause the projection etc.
**/
enum ProjectionHandlerResult {
	Success;

	/** This prevents further updates until manual action is taken to fix the issue. **/
	BlockedOnEvent(err:Error);

	/** Intentionally skip this event. Probably because it was unable to be processed but blocking would be more disruptive. **/
	SkippedEvent(reason:String);

	/** TODO: decide if we allow specifying retry options (like maxAttempts, maxRetryDuration), or if we just have sensible defaults. **/
	Retry;

	// We may also want a "WaitForOtherStream(source:EventSource)" or similar, for when you're reading from multiple streams and the messages are interdependent.
	// See https://stackoverflow.com/questions/47482906/cqrs-read-side-multiple-event-stream-topics-concurrency-race-conditions
}

/**
	Orchestrators
	=============

	Our various types of Back End Data Services all need to interact with each other, subscribing to event streams, and loading data, etc.

	The Small Universe framework attempts to "orchestrate" the communication between these services so you don't have to.

	There are multiple strategies you could use to orchestrate these, see implementations of `Orchestrator` for examples of what we've done so far.
**/
/**
	A Command is a request to add an Event to a particular EventSource.

	Pages have "actions", and when these bubble up to the server the PageAPI turns it into a Command.

	It is then used to add the Event to the EventSource.
**/
abstract Command<Event>(
	// TODO: Perhaps instead of an Option, this should be an Array
	// Empty array would still signify no command
	// But it would also allow us to have a page action specify _multiple_ commands
	// This would be nice for things like writing to TodoListEventSourceV1 and TodoListEventSourceV2 simultaneously during a handover.
	// It would raise gnarly questions about what to do if one event source accepts it, and one rejects it though.
	Option<{eventSourceClass:Class<EventSource<Event>>, event:Event}>
) from Option<{eventSourceClass:Class<EventSource<Event>>, event:Event}> {
	public function new(
		eventSourceClass:Class<EventSource<Event>>,
		event:Event
	) {
		this = Some({eventSourceClass: eventSourceClass, event: event});
	}

	public static var DoNothing:Command<Any> = None;
}

/**
	An Orchestrator is responsible for the flow of commands and events through our backend services.

	It makes sure a `Command` is sent to the relevant `EventSource` service, and if accepted, that the `Projection` services subscribed to it are updated.
	It is also responsible for ensuring projections are "caught up" if they fall behind.
**/
interface Orchestrator {
	/** Actions to be performed before we begin handling new commands. **/
	public function setup():Promise<Noise>;

	/** Handle a command by delegating to the appropriate EventSource. **/
	public function handleCommand(command:Command<Any>):Promise<Noise>;

	/**
		Clean up allocated resources immediately before the process is shut down.

		Note a teardown() needs to happen synchronously, the process will exit immediately after.

		In NodeJS for example, it is called during the `process.on('exit')` and `process.on('uncaughtException')` handlers, meaning any additional work still in the event loop after this will be abandoned.
		This allows you to perform synchronous cleanup of allocated resources (e.g. file descriptors, handles, etc) before shutting down the process. 
		See https://nodejs.org/docs/latest-v10.x/api/process.html#process_warning_using_uncaughtexception_correctly for examples of correct usage.
	**/
	public function teardown():Void;

	/**
		Get the PageApi for the current page.
	**/
	public function apiForPage(page:Page<Any, Any, Any>):PageApi<Any, Any, Any>;

	// Should the Orchestrator also be responsible for handling pages?
	// The code for these in NodeJS isn't much, but it's also not platform specific and could be shared.
	// I don't know that it would vary between Orchestrator implementations either though...
	// public function handlePageAction(resolvedRoute, action):Promise<Noise>;
	// public function getPageData(resolvedRoute):Promise<Data>;
	// public function getPageHtml(resolvedRoute):Promise<String>;
}

// These are not used yet, but could be useful in our orchestrators. It may also be useful for PageApis to know the status of various projections.
// enum SubscriberStatus {
// 	ReadyForEvents(status:SubscriberReadyStatus);
// 	NotReady(status:SubscriberNotReadyStatus);
// }
// enum SubscriberReadyStatus {
// 	UpToDate;
// 	Processing;
// }
// enum SubscriberNotReadyStatus {
// 	NotInitialised;
// 	ProcessingBacklog;
// 	Stalled;
// }

/**
	View Functions
	==============

	Our views are built using functions. This is inspired by Elm.

	Under the hood, they are simple data structures based on Haxe enums.
	We then use these to render, either as a string in Server Side Rendering, or using a Virtual DOM system in a browser Single Page Application.

	Design goals for our view functions:
	- Have a uni-directional data flow (data down, events up)
	- Use simple functions to create reusable "components", similar to Elm. (In React, more like functions that return JSX than class components or functional components).
	- Work equally well client side and server side
	- Implement local state in components, but still following "The Elm Architecture" of state/render/update functions.
**/
/**
	`HtmlType` is the core data structure that is created by our view functions.

	In general the helpers in `smalluniverse.DOM` and the `Html` wrapper are more convenient to use than creating these values directly.
**/
enum HtmlType<Action> {
	Element(
		tag:String,
		attrs:Array<HtmlAttribute<Action>>,
		children:Html<Action>
	);
	Text(text:String);
	Comment(text:String);
	Fragment(nodes:Array<Html<Action>>);
	// TODO: Component
}

/**
	`HtmlAttribute` allows you to set attributes, properties, and event listeners on an element.

	In general the helpers in `smalluniverse.DOM` are more convenient to use than creating these values directly.
**/
enum HtmlAttribute<Action> {
	/** A plain HTML attribute. eg `Attribute("class","title")` on a div would generate `<div class="title">` **/
	Attribute(name:String, value:String);

	/** A boolean/toggleable attribute. eg `BooleanAttribute(disabled,true)` on an input would generate `<input disabled>` **/
	BooleanAttribute(name:String, value:Bool);

	/** Set a JavaScript property. These sometimes overlap with attributes, but sometimes are more JS specific. eg `Property("currentTime", 35)` on a video be the equivalent to executing `myVideo.currentTime = 35` **/
	Property(name:String, value:Any);

	/** Add an event listener. eg `Event("click", e -> Some(SendEmail))` will cause a SendEmail action to occur when the element is clicked. **/
	Event(on:String, fn:(e:Event) -> Option<Action>);
}

/**
	A convient way to generate HtmlType values for our views.

	This wraps the `HtmlType` values under the hood but:
	- Automatically casts strings into "Text" nodes
	- Automatically casts arrays of Html into Fragment nodes.
	- Treats an empty text string as "void" (display nothing).
	- Provides an iterator for easily viewing all of the Html nodes regardless of there are 0, 1 or multiple nodes.
**/
abstract Html<Action>(
	HtmlType<Action>
) from HtmlType<Action> to HtmlType<Action> {
	@:from public static function fromString<T>(str:String):Html<T> {
		return Text(str);
	}

	@:from public static function fromArray<T>(nodes:Array<Html<T>>):Html<T> {
		return Fragment(nodes);
	}

	public var length(get, never):Int;
	public var type(get, never):HtmlType<Action>;

	public function iterator():Iterator<Html<Action>> {
		return switch this {
			case Fragment(nodes):
				return nodes.iterator();
			case Text(""):
				// Treat an empty string as void
				return [].iterator();
			default:
				return [this].iterator();
		}
	}

	function get_length():Int {
		return switch this {
			case Fragment(nodes):
				return nodes.length;
			case Text(""):
				// Treat an empty string as void
				return 0;
			default:
				return 1;
		}
	}

	function get_type():HtmlType<Action> {
		return this;
	}
}

// Not implemented yet.
// interface Component<Props, State, InnerAction, OuterAction> {
// 	function render(props:Props, state:State):Html<InnerAction>;
// 	function defaultState(props:Props):State;
// 	function update(
// 		currentState:State,
// 		action:InnerAction
// 	):{newState:State, outerAction:Option<OuterAction>}
// }

function mapHtml<
	InnerAction,
	OuterAction
	>(
		html:Html<InnerAction>,
		convert:InnerAction->Option<OuterAction>
	):Html<OuterAction> {
		switch html {
			case Element(tag, attrs, children):
				return Element(
					tag,
					attrs.map(a -> mapAttr(a, convert)),
					mapHtml(children, convert)
				);
			case Text(text):
				return Text(text);
			case Comment(text):
				return Comment(text);
			case Fragment(nodes):
				return Fragment(nodes.map(n -> mapHtml(n, convert)));
		}
}

function mapAttr<
	InnerAction,
	OuterAction
	>(
		attr:HtmlAttribute<InnerAction>,
		convert:InnerAction->Option<OuterAction>
	):HtmlAttribute<OuterAction> {
		switch attr {
			case Attribute(name, value):
				return Attribute(name, value);
			case BooleanAttribute(name, value):
				return BooleanAttribute(name, value);
			case Property(name, value):
				return Property(name, value);
			case Event(on, innerFn):
				function outerFn(e) {
					switch innerFn(e) {
						case Some(v):
							return convert(v);
						case None:
							return None;
					}
				}
				return Event(on, outerFn);
		}
}
