package smalluniverse.orchestrators;

import smalluniverse.util.LogUtils.getClassName;
import smalluniverse.SmallUniverse;

using tink.CoreApi;
using Lambda;

typedef SynchronousOrchestratorConfig = {
	eventSources:Array<EventSource<Any>>,
	projections:Array<Projection<Any>>,
	pageApis:Array<PageApi<Any, Any, Any>>
}

typedef SubscriptionsToEventSource = {
	source:EventSource<Any>,
	projections:Array<Projection<Any>>
};

/**
	An Orchestrator that attempts to update projections during the same HTTP Request as the Event Source.

	This is useful for:
	- Environments where there is no long lived process (eg AWS Lambda or PHP)
	- Simple to reason about local development

	To keep this implementation simple:
	- All projections must attempt to process their backlogs in setup() before we start taking requests.
	- All events are handled in all projections during the same request - they might return a promise but they're synchronous in the sense that the command HTTP response is blocked until projections are processed.
	- If a projection gets stalled on an event, we stop updating that projection.

	A more robust system would update the projections separately, perhaps in a separate process, or even on a separate server.
	This would allow projections to fail, fall behind, and catch up in a resilient way.
**/
class SynchronousOrchestrator implements Orchestrator {
	/** A map of the pageApis we know of, with the name of the related page as the key. **/
	var pageApis:Map<String, PageApi<Any, Any, Any>>;

	/** A list of the event sources and the projections that are subscribed to them. **/
	var eventSourcesAndSubscriptions:Array<SubscriptionsToEventSource> = [];

	public function new(setup:SynchronousOrchestratorConfig) {
		this.pageApis = [for (api in setup.pageApis) Type.getClassName(
			api.relatedPage
		) => api];

		this.eventSourcesAndSubscriptions = [
			for (eventSource in setup.eventSources)
				{
					source: eventSource,
					projections: []
				}
		];
		for (projection in setup.projections) {
			final subscription = getSubscriptionsToEventSource(
				projection.source
			);
			if (subscription == null) {
				throw new Error(
					501,
					'Projection "${getClassName(projection)}" is subscribed to an EventSource "${Type.getClassName(projection.source)}" which we do not have registered'
				);
			}
			subscription.projections.push(projection);
		}
	}

	public function setup():Promise<Noise> {
		return bringEventSourceProjectionsUpToDate()
				.next(_ -> bringProjectionsUpToDate());
	}

	public function handleCommand(command:Command<Any>):Promise<Noise> {
		final handleEventPromises = command.eventsToAttempt.map(attempt -> {
			final eventSourceClass = attempt.eventSourceClass;
			final event = attempt.event;
			final subscription = getSubscriptionsToEventSource(
				eventSourceClass
			);
			if (subscription == null) {
				// It would be nice to make this state impossible, but it's hard to imagine a clean API for doing so.
				// One option could be to do a macro-powered compile time check that all calls to `new Command()` are for Event Sources we have registered.
				throw new Error(
					501,
					'A command was called for EventSource "${Type.getClassName(eventSourceClass)}" but no EventSource of this type was registered'
				);
			}
			final eventSource = subscription.source;

			// Attempt the event on the eventSource and wait for it to either accept or reject.
			final eventSourceResult = eventSource.handleCommand(event);

			// Here is the naive implementation for this "synchronous" orchestrator.
			// If the eventSource was updated successfully, update all subscribed projections that are up-to-date, and ignore any that are already behind.

			final projections = subscription.projections;
			final projectionsResult = eventSourceResult.next((eventId) -> {
				// Trigger all projections in parallel, wait for all to complete, and log (then ignore) failures.
				// TODO: It my also be desirable for some projections to explicitly label themselves as async (and we never wait for them)
				return Promise
						.inParallel(
						projections.map(
							projection -> isProjectionUpToDate(
								eventSource,
								projection
							).next(upToDate -> switch upToDate {
								case true:
									return updateSubscription(
										projection,
										event
									).recover(err -> {
										trace(
											'Error updating projection ${getClassName(projection)}',
											err.toString()
										);
										return Noise;
									});
								case false:
									// The projection isn't up-to-date, so lets not add this event, or things will arrive out of order.
									// This projection will now be behind the EventSource until the next time `processBacklog()` is called.
									return Noise;
							})
						)
					)
						.noise();
			});
			return projectionsResult.eager();
		});
		return Promise.inParallel(handleEventPromises).noise();
	}

	public function teardown() {}

	public function apiForPage<
		Action
		,
		Params
		,
		Data
		>(page:Page<Action, Params, Data>):PageApi<Action, Params, Data> {
		final pageClassName = getClassName(page);
		final api = this.pageApis[pageClassName];
		if (api == null) {
			throw new Error(
				InternalError,
				'Page ${pageClassName} does not have a corresponding PageApi added to your SynchronousOrchestrator'
			);
		}
		return cast api;
	}

	public function bringEventSourceProjectionsUpToDate():Promise<Noise> {
		final projectionUpdates = [];
		for (subscription in eventSourcesAndSubscriptions) {
			final eventSource = subscription.source;
			final eventSourceProjection = @:nullSafety(Off) Std.downcast(
				eventSource,
				EventSourceWtihProjection
			);
			if (eventSourceProjection != null) {
				final projectionUpdatedPromise = isProjectionUpToDate(
					eventSource,
					eventSourceProjection
				).next(isUpToDate -> {
					if (isUpToDate) {
						return Promise.resolve(Noise);
					}
					return processBacklog(eventSource, eventSourceProjection);
				});
				final name = getClassName(eventSource);
				projectionUpdatedPromise.handle(outcome -> switch outcome {
					case Success(_):
						trace('EventSourceProjection ${name} is up to date');
					case Failure(err):
						trace(
							'Failed to bring EventSourceProjection ${name} up to date.\n--> $err'
						);
				});
				projectionUpdates.push(projectionUpdatedPromise);
			}
		}
		return Promise.inParallel(projectionUpdates).noise();
	}

	public function bringProjectionsUpToDate():Promise<Noise> {
		final projectionUpdates = [];
		for (subscription in eventSourcesAndSubscriptions) {
			final eventSource = subscription.source;
			for (projection in subscription.projections) {
				final projectionUpdatedPromise = isProjectionUpToDate(
					eventSource,
					projection
				).next(isUpToDate -> {
					if (isUpToDate) {
						return Promise.resolve(Noise);
					}
					return processBacklog(eventSource, projection);
				});
				final name = getClassName(projection);
				projectionUpdatedPromise.handle(outcome -> switch outcome {
					case Success(_):
						trace('Projection ${name} is up to date');
					case Failure(err):
						trace(
							'Failed to bring Projection ${name} up to date.\n--> $err'
						);
				});
				projectionUpdates.push(projectionUpdatedPromise);
			}
		}
		return Promise.inParallel(projectionUpdates).noise();
	}

	function getSubscriptionsToEventSource(
		eventSourceClass:Class<EventSource<Any>>
	):Null<SubscriptionsToEventSource> {
		return eventSourcesAndSubscriptions.find(
			item -> Type.getClass(item.source) == eventSourceClass
		);
	}
}

function isProjectionUpToDate<Event>(
	eventSource:EventSource<Event>,
	projection:InternalOrExternalProjection<Event>
):Promise<Bool> {
	return Promise.inParallel([
		projection.getBookmark(),
		eventSource.getLatestEvent()
	]).next(bookmarks -> {
		if (bookmarks[0] == bookmarks[1]) {
			// Projection is up to date!
			return Promise.resolve(true);
		}
		return Promise.resolve(false);
	});
}

/** Process the backlog of events for a specific projection/eventSource subscription. **/
function processBacklog<Event>(
	eventSource:EventSource<Event>,
	projection:InternalOrExternalProjection<Event>
):Promise<Noise> {
	final pageSize = 20;
	return projection
			.getBookmark()
			.next(
			startAfter -> readEvents(
				eventSource,
				projection,
				pageSize,
				// TODO: is there a bug here where startFrom != startAfter?
				startAfter
			)
		);
}

/** Read events from an event source and process them in a projection, one page at a time. **/
function readEvents<Event>(
	eventSource:EventSource<Event>,
	projectionSubscription:InternalOrExternalProjection<Event>,
	pageSize:Int,
	startFrom:Option<EventId>
):Promise<Noise> {
	return eventSource
			.readEvents(pageSize, startFrom)
			.next((events) -> // Process all the events one at a time
			events
					.fold(
					(
						event:{id:EventId, payload:Event},
						promise:Promise<Noise>
					) -> promise.next(
						_ -> updateSubscription(projectionSubscription, event)
					),
					Promise.resolve(Noise)
				)
					.next(_ -> {
					// Read the next page, or return "Noise" if we're all done
					if (events.length < pageSize) {
						// We're up to date!
						// TODO: should we compare `eventSource.getLatestEvent()` instead?
						return Noise;
					}
					final lastEventId = events[events.length - 1].id;
					return readEvents(
						eventSource,
						projectionSubscription,
						pageSize,
						Some(lastEventId)
					);
				})
		);
}

/** Attempt to process a single event on a single projection, including retries. **/
function updateSubscription<Event>(
	projection:InternalOrExternalProjection<Event>,
	event:{
		id:EventId,
		payload:Event
	},
	retryAttempt:Int = 0
):Promise<Noise> {
	return projection
			.handleEvent(event.id, event.payload)
			.next(function(result) switch result {
			case Success:
				return Noise;
			case BlockedOnEvent(err):
				return Promise.reject(err);
			case SkippedEvent(reason):
				trace(
					'Skipping event ${event.id} for ${getClassName(projection)})'
				);
				return Noise;
			case Retry:
				final MAX_RETRIES = 3;
				if (retryAttempt > MAX_RETRIES) {
					return Promise.reject(
						new Error(
							'Max retries reached for event ${event.id} on ${getClassName(projection)}'
						)
					);
				}
				return Future
						.delay(1000 * retryAttempt, Noise)
						.flatMap(
						_ -> updateSubscription(
							projection,
							event,
							retryAttempt + 1
						)
					);
		});
}
