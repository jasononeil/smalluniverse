package smalluniverse.util;

import smalluniverse.SmallUniverse;
import js.node.Fs;

using tink.CoreApi;

function readJson<T>(file:String, encoder:IJsonEncoder<T>):Promise<T> {
	final trigger = Promise.trigger();
	Fs.readFile(file, {encoding: "utf8"}, (err, jsonContent) -> {
		if (err != null) {
			trigger.reject(Error.ofJsError(err));
		} else {
			try {
				trigger.resolve(encoder.decode(jsonContent));
			} catch (e) {
				trigger.reject(
					Error.withData(
						501,
						'Failed to parse ${file} as valid data for our model: ${e}',
						e
					)
				);
			}
		}
	});
	return trigger.asPromise();
}

function writeJson<T>(
	file:String,
	content:T,
	encoder:IJsonEncoder<T>
):Promise<T> {
	final trigger = Promise.trigger();
	final jsonContent = encoder.encode(content);
	Fs.writeFile(file, jsonContent, {encoding: "utf8"}, (err) -> {
		if (err != null) {
			trigger.reject(Error.ofJsError(err));
		} else {
			trigger.resolve(content);
		}
	});
	return trigger.asPromise();
}
