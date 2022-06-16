package mealplanner.helpers;

import datetime.DateTime;

using tink.CoreApi;

/** A yyyy-mm-dd string. **/
@:jsonParse(json -> "" + json)
@:jsonStringify(dateString -> "" + dateString)
abstract DateString(String) to String from String {
	function new(date:String) {
		// Check for yyyy-mm-dd format, but don't validate the date itself
		if (~/^\d{4}-\d{2}-\d{2}$/.match(date)) {
			this = date;
		} else {
			throw new Error(
				InternalError,
				'Date string ${date} was not in yyyy-mm-dd format'
			);
		}
	}

	@:to public static inline function toDateTime(
		dateString:DateString
	):DateTime {
		return DateTime.fromString(dateString);
	}

	@:from public static inline function fromString(date:String)
		return new DateString(date);

	@:from public static function fromDateTime(date:DateTime)
		return new DateString(date.format("%F"));
}
