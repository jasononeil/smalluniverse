package smalluniverse.eventsources;

import smalluniverse.SmallUniverse;
import smalluniverse.util.JsonFiles;

using tink.CoreApi;
using Lambda;

class JsonFileEventSource<
	Event
	,
	Model
	> extends BasicEventSource<Event>
		implements EventSourceWtihProjection<Event> {
	var writeModelJsonFile:String;
	var modelJsonEncoder:IJsonEncoder<Model>;
	var updateModelForEvent:Model->Event->Promise<Model>;
	var bookmarkManager:BookmarkManager;
	var bookmarkId:String;

	public function new(
		eventStore:EventStore<Event>,
		writeModelJsonFile:String,
		modelJsonEncoder:IJsonEncoder<Model>,
		updateModelForEvent:Model->Event->Promise<Model>,
		bookmarkManager:BookmarkManager
	) {
		super(eventStore);
		this.writeModelJsonFile = writeModelJsonFile;
		this.modelJsonEncoder = modelJsonEncoder;
		this.updateModelForEvent = updateModelForEvent;
		this.bookmarkManager = bookmarkManager;
		this.bookmarkId = 'JsonFileEventSource $writeModelJsonFile';
	}

	/** When a command is being attempted for the first time (and may be rejected before publishing as an Event). **/
	override public function handleCommand(event:Event):Promise<EventId> {
		return readModel()
				.next(model -> updateModelForEvent(model, event))
				.next(
				updatedModel -> this.store
						.publish(event)
						.next(
						eventId -> writeModel(
							updatedModel
						)
								.next(
								_ -> bookmarkManager.updateBookmark(
									bookmarkId,
									eventId
								)
							)
								.next(_ -> eventId)
					)
			);
	}

	/** When a prior event is being replayed because we are rebuilding the projection. **/
	public function handleEvent(
		eventId:EventId,
		event:Event
	):Promise<ProjectionHandlerResult> {
		return readModel()
				.next(model -> updateModelForEvent(model, event))
				.next(updatedModel -> writeModel(updatedModel))
				.next(
				modelWithBookmark -> bookmarkManager.updateBookmark(
					bookmarkId,
					eventId
				)
			)
				.next(_ -> ProjectionHandlerResult.Success);
	}

	public function getBookmark() {
		return bookmarkManager.getBookmark(bookmarkId);
	}

	function readModel():Promise<Model> {
		return readJson(writeModelJsonFile, modelJsonEncoder);
	}

	function writeModel(model:Model):Promise<Model> {
		return writeJson(writeModelJsonFile, model, modelJsonEncoder);
	}
}
