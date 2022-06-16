package smalluniverse.eventlogs;

import smalluniverse.SmallUniverse;
import js.node.Fs;
import uuid.Uuid.v4;

using tink.CoreApi;
using StringTools;

/**
	A simple event store that stores events in "Tab Separated Value" (TSV) format in a local flat file.

	Each row has the format:

	```
	${eventId}\t${eventJson}
	```

	This should probably not be used in production environments that expect significant traffic.

	It is useful for easy-to-inspect local development.
	Or more truthfully, for when I'm hacking on this project and don't want to start learning https://github.com/haxetink/tink_sql or setting up a database yet.
**/
@:generic
class TSVEventStore<Event> implements EventStore<Event> {
	var file:String;
	var encoder:IJsonEncoder<Event>;

	public function new(file:String, encoder:IJsonEncoder<Event>) {
		this.file = file;
		this.encoder = encoder;
	}

	public function publish(event:Event):Promise<EventId> {
		final eventId = v4();
		final json = encoder.encode(event);
		final row = '$eventId\t$json';
		final completionTrigger = Promise.trigger();
		Fs.appendFile(file, row + "\n", {encoding: "utf8"}, (err) -> {
			if (err != null) {
				completionTrigger.reject(Error.ofJsError(err));
			} else {
				completionTrigger.resolve(eventId);
			}
		});
		return completionTrigger;
	}

	public function getLatestEvent():Promise<Option<EventId>> {
		return readFile().next(content -> {
			// Last row will be an empty line, so trim first.
			final trimmedContent = content.trim();
			if (trimmedContent != "") {
				final lastLine = trimmedContent.split("\n").pop();
				if (lastLine == null) {
					throw "TODO";
				}
				final parts = lastLine.split('\t');
				final eventId = parts[0];
				return Some(eventId);
			}
			return None;
		});
	}

	public function readEvents(
		numberToRead:Int,
		startingFrom:Option<EventId>
	):Promise<Array<{
		id:EventId,
		payload:Event
		}>> {
		return readFile().next(content -> {
			final startOfNextEvent = switch startingFrom {
				case Some(eventId):
					final eventIdFragment = '\n${eventId}\t';
					final startOfLastEvent = content.indexOf(eventIdFragment);
					if (startOfLastEvent == -1) {
						return new Error(
							'Error: startFrom event "${eventId}" was not found, behaviour undefined'
						);
					}
					content.indexOf(
						"\n",
						startOfLastEvent + eventIdFragment.length
					);
				case None:
					0;
			}
			final remainingContent = content.substr(startOfNextEvent);

			final rows = remainingContent
					.split("\n")
					.map(line -> StringTools.trim(line))
					.filter(line -> line != "")
					.slice(0, numberToRead);

			try {
				return rows.map(row -> {
					final parts = row.split('\t');
					return {
						id: parts[0],
						payload: try {
							encoder.decode(parts[1]);
						} catch (err:Any) {
							throw 'Failed to decode event: ${parts[0]} ${parts[1]}.\n--> $err';
						}
					}
				});
			} catch (err:Any) {
				return new Error(
					'Error while reading events from $file.\n--> $err'
				);
			}
		});
		}

	function readFile():Promise<String> {
		var trigger = Promise.trigger();
		// We could use https://lib.haxe.org/p/asys to make this not NodeJS specific.
		Fs.readFile(file, {encoding: "utf8"}, (err, content) -> {
			if (err != null) {
				trigger.reject(Error.ofJsError(err));
			} else {
				trigger.resolve(content);
			}
		});
		return trigger.asPromise();
	}
}
