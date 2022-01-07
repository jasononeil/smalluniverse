package smalluniverse.eventsources;

import smalluniverse.SmallUniverse;
import js.node.Fs;

using tink.CoreApi;
using Lambda;

enum ShoppingListEvent {}
typedef ShoppingListModel = {}

class JsonFileEventSource<Event, Model> extends BasicEventSource<Event> {
	var writeModelJsonFile:String;
	var modelJsonEncoder:IJsonEncoder<Model>;
	var updateModelForEvent:Model->Event->Promise<Model>;

	public function new(
		eventStore:EventStore<Event>,
		writeModelJsonFile:String,
		modelJsonEncoder:IJsonEncoder<Model>,
		updateModelForEvent:Model->Event->Promise<Model>
	) {
		super(eventStore);
		this.writeModelJsonFile = writeModelJsonFile;
		this.modelJsonEncoder = modelJsonEncoder;
		this.updateModelForEvent = updateModelForEvent;
	}

	override public function handleEvent(event:Event):Promise<EventId> {
		return readModel()
				.next(model -> updateModelForEvent(model, event))
				.next(model -> writeModel(model))
				.next(_ -> this.store.publish(event));
	}

	function readModel():Promise<Model> {
		final trigger = Promise.trigger();
		Fs.readFile(
			writeModelJsonFile,
			{encoding: "utf8"},
			(err, jsonContent) -> {
				if (err != null) {
					trigger.reject(Error.ofJsError(err));
				} else {
					try {
						final model:Model = modelJsonEncoder.decode(
							jsonContent
						);
						trigger.resolve(model);
					} catch (e) {
						final className = @:nullSafety(Off) Type.getClassName(
							Type.getClass(this)
						);
						trigger.reject(
							Error.withData(
								501,
								'Failed to parse ${writeModelJsonFile} as valid data for our model in ${className}: ${e}',
								e
							)
						);
					}
				}
			}
		);
		return trigger.asPromise();
	}

	function writeModel(model:Model):Promise<Noise> {
		final trigger = Promise.trigger();
		final jsonContent = modelJsonEncoder.encode(model);
		Fs.writeFile(
			writeModelJsonFile,
			jsonContent,
			{encoding: "utf8"},
			(err) -> {
				if (err != null) {
					trigger.reject(Error.ofJsError(err));
				} else {
					trigger.resolve(Noise);
				}
			}
		);
		return trigger.asPromise();
	}
}
