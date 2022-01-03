package smalluniverse.orchestrators;

import smalluniverse.SmallUniverse.Command;
import smalluniverse.SmallUniverse.ProjectionSubscriptions;
import smalluniverse.SmallUniverse.EventSource;
import smalluniverse.SmallUniverse.Projection;
import smalluniverse.SmallUniverse.Orchestrator;
import smalluniverse.SmallUniverse.EventId;

using tink.CoreApi;
using Lambda;

typedef Subscription = {
	source:EventSource<Any>,
	projections:Array<ProjectionSubscriptions<Any>>
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
	var subscriptions:Array<Subscription> = [];

	public function new(
		setup:{eventSources:Array<EventSource<Any>>, projections:Array<Projection>}
	) {
		this.subscriptions = [for (eventSource in setup.eventSources) {
			source: eventSource,
			projections: []
		}];
		for (projection in setup.projections) {
			for (projectionSubscription in projection.subscriptions) {
				final subscription = getSubscription(
					projectionSubscription.source
				);
				if (subscription == null) {
					throw new Error(
						501,
						'Projection "${projectionSubscription.name}" is subscribed to an EventSource "${Type.getClassName(projectionSubscription.source)}" we do not have registered'
					);
				}
				subscription.projections.push(projectionSubscription);
			}
		}
	}

	public function setup():Promise<Noise> {
		return bringProjectionsUpToDate();
	}

	public function handleCommand(command:Command<Any>):Promise<Noise> {
		switch command {
			case Some({eventSourceClass: eventSourceClass, event: event}):
				final subscription = getSubscription(eventSourceClass);
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
				final eventSourceResult = eventSource.handleEvent(event);

				// Here is the naive implementation for this "synchronous" orchestrator.
				// If the eventSource was updated successfully, update all subscribed projections
				// One limitation here that may lead to bugs: new events will be processed even if a backlog is still underway, leading to events being processed out of order.

				final projectionSubscriptions = subscription.projections;
				final projectionsResult = eventSourceResult.next((eventId) -> {
					// Trigger all projections in parallel, wait for all to complete, and log (then ignore) failures.
					// TODO: It my also be desirable for some projections to explicitly label themselves as async (and we never wait for them)
					return Future
							.inParallel(
							// TODO: we should check the projection is up-to-date before we start here to avoid out-of-order events.
							// If it's not, we can just ignore it and leave it for the next processBacklog()
							// ...or we can implement a queue system for a small number of events.4
							projectionSubscriptions.map(
								sub -> return updateSubscription(
									sub,
									event
								).recover(err -> {
									trace(
										'Error updating subscription ${sub.name}',
										err.toString()
									);
									return Noise;
								})
							)
						)
							.noise();
				});
				return projectionsResult;
			case None:
				return Promise.resolve(Noise);
		}
	}

	public function teardown() {}

	public function bringProjectionsUpToDate():Promise<Noise> {
		final projectionUpdates = [];
		for (subscription in subscriptions) {
			final eventSource = subscription.source;
			for (projectionSubscription in subscription.projections) {
				projectionUpdates.push(
					isProjectionUpToDate(
						eventSource,
						projectionSubscription
					).next(isUpToDate -> {
						if (isUpToDate) {
							return Promise.resolve(Noise);
						}
						return processBacklog(
							eventSource,
							projectionSubscription
						);
					})
				);
			}
		}
		return Promise.inParallel(projectionUpdates).noise();
	}

	function getSubscription(
		eventSourceClass:Class<EventSource<Any>>
	):Null<Subscription> {
		return this.subscriptions.find(
			item -> Type.getClass(item.source) == eventSourceClass
		);
	}
}

function isProjectionUpToDate<Event>(
	eventSource:EventSource<Event>,
	projectionSubscription:ProjectionSubscriptions<Event>
):Promise<Bool> {
	return Promise.inParallel([
		projectionSubscription.getBookmark(),
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
	projectionSubscription:ProjectionSubscriptions<Event>
):Promise<Noise> {
	final pageSize = 20;
	return projectionSubscription
			.getBookmark()
			.next(
			startAfter -> readEvents(
				eventSource,
				projectionSubscription,
				pageSize,
				// TODO: is there a bug here where startFrom != startAfter?
				startAfter
			)
		);
}

/** Read events from an event source and process them in a projection, one page at a time. **/
function readEvents<Event>(
	eventSource:EventSource<Event>,
	projectionSubscription:ProjectionSubscriptions<Event>,
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
					final lastEventId = events[events.length - 1].id;
					if (events.length < pageSize) {
						// We're up to date!
						// TODO: should we compare `eventSource.getLatestEvent()` instead?
						return Noise;
					}
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
	projectionSubscription:ProjectionSubscriptions<Event>,
	event:{
		id:EventId,
		payload:Event
	},
	retryAttempt:Int = 0
):Promise<Noise> {
	return projectionSubscription
			.handler(event)
			.next(function(result) switch result {
			case Success:
				return Noise;
			case BlockedOnEvent(err):
				return Promise.reject(err);
			case SkippedEvent(reason):
				trace(
					'Skipping event ${event.id} for ${projectionSubscription.name}'
				);
				return Noise;
			case Retry:
				final MAX_RETRIES = 3;
				if (retryAttempt > MAX_RETRIES) {
					return Promise.reject(
						new Error(
							'Max retries reached for event ${event.id} on ${projectionSubscription.name}'
						)
					);
				}
				return Future
						.delay(1000 * retryAttempt, Noise)
						.flatMap(
						_ -> updateSubscription(
							projectionSubscription,
							event,
							retryAttempt + 1
						)
					);
		});
}
