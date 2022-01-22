package mealplanner.helpers;

import haxe.PosInfos;

using tink.CoreApi;

/** Make a possibly null value not null by providing a fallback. **/
function or<T>(value:Null<T>, fallback:T):T {
	return value != null ? value : fallback;
}

/**
	Make a possibly null value not null by providing a function to get a fallback.
	Also useful for causing side-effects in the case of a fallback.
**/
function orGet<T>(value:Null<T>, fallback:() -> T):T {
	return value != null ? value : fallback();
}

/**
	For when we're pretty sure it's not null and need to assert it.
**/
function sure<T>(value:Null<T>, ?pos:PosInfos):T {
	if (value == null) {
		throw new Error(
			InternalError,
			'Had a null value when we were sure we would not',
			pos
		);
	}
	return value;
}
