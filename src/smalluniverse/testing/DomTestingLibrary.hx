package smalluniverse.testing;

import js.html.Node;
import js.html.Element;
import js.lib.Promise;
import haxe.extern.EitherType;
import Snabbdom;

@:jsRequire("@testing-library/dom")
extern class DomTestingLibrary {
	/** Calling this before using other features of this class is required. **/
	public inline static function setupJsdom():Void {
		js.Lib.require("global-jsdom/register");
	}

	// ===============================
	// Queries Accessible to Everyone
	// ===============================
	//
	// ByRole
	//

	/**
		Get nodes by role
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByRole(
		container:Element,
		text:TextMatch,
		?options:ByRoleOptions
	):Element;

	/**
		Get nodes by role
		Returns an array of all matching nodes for a query, and throws an error if no elements match.
	**/
	public static function getAllByRole(
		container:Element,
		text:TextMatch,
		?options:ByRoleOptions
	):Array<Element>;

	/**
		Get nodes by role
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByRole(
		container:Element,
		text:TextMatch,
		?options:ByRoleOptions
	):Null<Element>;

	/**
		Get nodes by role
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByRole(
		container:Element,
		text:TextMatch,
		?options:ByRoleOptions
	):Array<Element>;

	/**
		Get nodes by role
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByRole(
		container:Element,
		text:TextMatch,
		?options:ByRoleOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by role
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByRole(
		container:Element,
		text:TextMatch,
		?options:ByRoleOptions
	):Promise<Array<Element>>;

	//
	// ByLabelText
	//

	/**
		Get nodes by label text
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByLabelText(
		container:Element,
		text:TextMatch,
		?options:ByLabelTextOptions
	):Element;

	/**
		Get nodes by label text
		Returns all the matching node(s) for a query, and throw a descriptive error if no elements match
	**/
	public static function getAllByLabelText(
		container:Element,
		text:TextMatch,
		?options:ByLabelTextOptions
	):Array<Element>;

	/**
		Get nodes by label text
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByLabelText(
		container:Element,
		text:TextMatch,
		?options:ByLabelTextOptions
	):Null<Element>;

	/**
		Get nodes by label text
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByLabelText(
		container:Element,
		text:TextMatch,
		?options:ByLabelTextOptions
	):Array<Element>;

	/**
		Get nodes by label text
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByLabelText(
		container:Element,
		text:TextMatch,
		?options:ByLabelTextOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by label text
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByLabelText(
		container:Element,
		text:TextMatch,
		?options:ByLabelTextOptions
	):Promise<Array<Element>>;

	//
	// ByPlaceHolderText
	//

	/**
		Get nodes by place holder text
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByPlaceHolderText(
		container:Element,
		text:TextMatch,
		?options:ByPlaceHolderTextOptions
	):Element;

	/**
		Get nodes by place holder text
		Returns all the matching node(s) for a query, and throw a descriptive error if no elements match
	**/
	public static function getAllByPlaceHolderText(
		container:Element,
		text:TextMatch,
		?options:ByPlaceHolderTextOptions
	):Array<Element>;

	/**
		Get nodes by place holder text
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByPlaceHolderText(
		container:Element,
		text:TextMatch,
		?options:ByPlaceHolderTextOptions
	):Null<Element>;

	/**
		Get nodes by place holder text
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByPlaceHolderText(
		container:Element,
		text:TextMatch,
		?options:ByPlaceHolderTextOptions
	):Array<Element>;

	/**
		Get nodes by place holder text
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByPlaceHolderText(
		container:Element,
		text:TextMatch,
		?options:ByPlaceHolderTextOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by place holder text
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByPlaceHolderText(
		container:Element,
		text:TextMatch,
		?options:ByPlaceHolderTextOptions
	):Promise<Array<Element>>;

	//
	// ByText
	//

	/**
		Get nodes by text
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByText(
		container:Element,
		text:TextMatch,
		?options:ByTextOptions
	):Element;

	/**
		Get nodes by text
		Returns all the matching node(s) for a query, and throw a descriptive error if no elements match
	**/
	public static function getAllByText(
		container:Element,
		text:TextMatch,
		?options:ByTextOptions
	):Array<Element>;

	/**
		Get nodes by text
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByText(
		container:Element,
		text:TextMatch,
		?options:ByTextOptions
	):Null<Element>;

	/**
		Get nodes by text
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByText(
		container:Element,
		text:TextMatch,
		?options:ByTextOptions
	):Array<Element>;

	/**
		Get nodes by text
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByText(
		container:Element,
		text:TextMatch,
		?options:ByTextOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by text
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByText(
		container:Element,
		text:TextMatch,
		?options:ByTextOptions
	):Promise<Array<Element>>;

	//
	// ByDisplayValue
	//

	/**
		Get nodes by display value
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByDisplayValue(
		container:Element,
		text:TextMatch,
		?options:ByDisplayValueOptions
	):Element;

	/**
		Get nodes by display value
		Returns all the matching node(s) for a query, and throw a descriptive error if no elements match
	**/
	public static function getAllByDisplayValue(
		container:Element,
		text:TextMatch,
		?options:ByDisplayValueOptions
	):Array<Element>;

	/**
		Get nodes by display value
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByDisplayValue(
		container:Element,
		text:TextMatch,
		?options:ByDisplayValueOptions
	):Null<Element>;

	/**
		Get nodes by display value
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByDisplayValue(
		container:Element,
		text:TextMatch,
		?options:ByDisplayValueOptions
	):Array<Element>;

	/**
		Get nodes by display value
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByDisplayValue(
		container:Element,
		text:TextMatch,
		?options:ByDisplayValueOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by display value
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByDisplayValue(
		container:Element,
		text:TextMatch,
		?options:ByDisplayValueOptions
	):Promise<Array<Element>>;

	// =================
	// Semantic Queries
	// =================
	//
	// ByAltText
	//

	/**
		Get nodes by alt text
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByAltText(
		container:Element,
		text:TextMatch,
		?options:ByAltTextOptions
	):Element;

	/**
		Get nodes by alt text
		Returns all the matching node(s) for a query, and throw a descriptive error if no elements match
	**/
	public static function getAllByAltText(
		container:Element,
		text:TextMatch,
		?options:ByAltTextOptions
	):Array<Element>;

	/**
		Get nodes by alt text
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByAltText(
		container:Element,
		text:TextMatch,
		?options:ByAltTextOptions
	):Null<Element>;

	/**
		Get nodes by alt text
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByAltText(
		container:Element,
		text:TextMatch,
		?options:ByAltTextOptions
	):Array<Element>;

	/**
		Get nodes by alt text
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByAltText(
		container:Element,
		text:TextMatch,
		?options:ByAltTextOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by alt text
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByAltText(
		container:Element,
		text:TextMatch,
		?options:ByAltTextOptions
	):Promise<Array<Element>>;

	//
	// ByTitle
	//

	/**
		Get nodes by title
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByTitle(
		container:Element,
		text:TextMatch,
		?options:ByTitleOptions
	):Element;

	/**
		Get nodes by title
		Returns all the matching node(s) for a query, and throw a descriptive error if no elements match
	**/
	public static function getAllByTitle(
		container:Element,
		text:TextMatch,
		?options:ByTitleOptions
	):Array<Element>;

	/**
		Get nodes by title
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByTitle(
		container:Element,
		text:TextMatch,
		?options:ByTitleOptions
	):Null<Element>;

	/**
		Get nodes by title
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByTitle(
		container:Element,
		text:TextMatch,
		?options:ByTitleOptions
	):Array<Element>;

	/**
		Get nodes by title
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByTitle(
		container:Element,
		text:TextMatch,
		?options:ByTitleOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by title
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByTitle(
		container:Element,
		text:TextMatch,
		?options:ByTitleOptions
	):Promise<Array<Element>>;

	// =========
	// Test IDs
	// =========
	//
	// ByTestId
	//

	/**
		Get nodes by test id
		Returns the matching node for a query, and throw a descriptive error if no elements match or if more than one match is found.
	**/
	public static function getByTestId(
		container:Element,
		text:TextMatch,
		?options:ByTestIdOptions
	):Element;

	/**
		Get nodes by test id
		Returns all the matching node(s) for a query, and throw a descriptive error if no elements match
	**/
	public static function getAllByTestId(
		container:Element,
		text:TextMatch,
		?options:ByTestIdOptions
	):Array<Element>;

	/**
		Get nodes by test id
		Returns the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. Throws an error if more than one match is found.
	**/
	public static function queryByTestId(
		container:Element,
		text:TextMatch,
		?options:ByTestIdOptions
	):Null<Element>;

	/**
		Get nodes by test id
		Returns an array of all matching nodes for a query, and return an empty array ([]) if no elements match.
	**/
	public static function queryAllByTestId(
		container:Element,
		text:TextMatch,
		?options:ByTestIdOptions
	):Array<Element>;

	/**
		Get nodes by test id
		Returns a Promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms.
	**/
	public static function findByTestId(
		container:Element,
		text:TextMatch,
		?options:ByTestIdOptions
	):js.lib.Promise<Element>;

	/**
		Get nodes by test id
		Returns a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.
	**/
	public static function findAllByTestId(
		container:Element,
		text:TextMatch,
		?options:ByTestIdOptions
	):Promise<Array<Element>>;

	public static var fireEvent:FireEventHelpers;
}

typedef RenderFunction = VNode->{
	container: Element,
	getByText: String -> Node
	// Anything else?
};

/**
	Most of the query APIs take a TextMatch as an argument, which means the argument can be either a string, regex, or a function which returns true for a match and false for a mismatch.
	https://testing-library.com/docs/queries/about#textmatch
**/
typedef TextMatch = EitherType<EitherType<String, EReg>, String->Bool>;

/**
	Before running any matching logic against text in the DOM, DOM Testing Library automatically normalizes that text. By default, normalization consists of trimming whitespace from the start and end of text, and collapsing multiple adjacent whitespace characters into a single space.

	If you want to prevent that normalization, or provide alternative normalization (e.g. to remove Unicode control characters), you can provide a normalizer function in the options object. This function will be given a string and is expected to return a normalized version of that string.

	https://testing-library.com/docs/queries/about#normalization
**/
typedef NormalizerFn = String->String;

typedef ByRoleOptions = {
	/** default true **/
	?exact:Bool,
	/** default false **/
	?hidden:Bool,
	?name:TextMatch,
	?normalizer:NormalizerFn,
	?selected:Bool,
	?checked:Bool,
	?pressed:Bool,
	?expanded:Bool,
	?queryFallbacks:Bool,
	?level:Float,
}

typedef ByLabelTextOptions = {
	/** default "*" **/
	?selector:String,
	/** default true **/
	?exact:Bool,
	?normalizer:NormalizerFn,
}

typedef ByPlaceHolderTextOptions = {
	/** default true **/
	?exact:Bool,
	?normalizer:NormalizerFn,
}

typedef ByTextOptions = {
	/** default "*" **/
	?selector:String,
	/** default true **/
	?exact:Bool,
	/** default "script, style" **/
	?ignore:EitherType<String, Bool>,
	?normalizer:NormalizerFn,
}

typedef ByDisplayValueOptions = {
	/** default true **/
	?exact:Bool,
	?normalizer:NormalizerFn,
}

typedef ByAltTextOptions = {
	/** default true **/
	?exact:Bool,
	?normalizer:NormalizerFn,
}

typedef ByTitleOptions = {
	/** default true **/
	?exact:Bool,
	?normalizer:NormalizerFn,
}

typedef ByTestIdOptions = {
	/** default true **/
	?exact:Bool,
	?normalizer:NormalizerFn,
}

extern class FireEventHelpers {
	// Clipboard Events
	function copy(node:Node, ?eventProperties:ComposableEventProperties):Void;
	function cut(node:Node, ?eventProperties:ComposableEventProperties):Void;
	function paste(node:Node, ?eventProperties:ComposableEventProperties):Void;
	// Composition Events
	function compositionEnd(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function compositionStart(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function compositionUpdate(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	// Keyboard Events
	function keyDown(node:Node, ?eventProperties:{
		bubbles:Bool,
		cancelable:Bool,
		charCode:Int,
		composed:Bool
	}):Void;
	function keyPress(node:Node, ?eventProperties:{
		bubbles:Bool,
		cancelable:Bool,
		charCode:Int,
		composed:Bool
	}):Void;
	function keyUp(node:Node, ?eventProperties:{
		bubbles:Bool,
		cancelable:Bool,
		charCode:Int,
		composed:Bool
	}):Void;
	// Focus Events
	function focus(node:Node, ?eventProperties:ComposableEventProperties):Void;
	function blur(node:Node, ?eventProperties:ComposableEventProperties):Void;
	function focusIn(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function focusOut(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	// Form Events
	function change(node:Node, ?eventProperties:EventProperties):Void;
	function input(node:Node, ?eventProperties:ComposableEventProperties):Void;
	function invalid(node:Node, ?eventProperties:EventProperties):Void;
	function submit(node:Node, ?eventProperties:EventProperties):Void;
	function reset(node:Node, ?eventProperties:EventProperties):Void;
	// Mouse Events
	function click(node:Node, ?eventProperties:{
		bubbles:Bool,
		cancelable:Bool,
		button:Int,
		composed:Bool
	}):Void;
	function contextMenu(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function dblClick(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function drag(node:Node, ?eventProperties:ComposableEventProperties):Void;
	function dragEnd(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function dragEnter(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function dragExit(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function dragLeave(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function dragOver(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function dragStart(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function drop(node:Node, ?eventProperties:ComposableEventProperties):Void;
	function mouseDown(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function mouseEnter(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function mouseLeave(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function mouseMove(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function mouseOut(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function mouseOver(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function mouseUp(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	// Selection Events
	function select(node:Node, ?eventProperties:EventProperties):Void;
	// Touch Events
	function touchCancel(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function touchEnd(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function touchMove(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function touchStart(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	// UI Events
	function scroll(node:Node, ?eventProperties:EventProperties):Void;
	// Wheel Events
	function wheel(node:Node, ?eventProperties:ComposableEventProperties):Void;
	// Media Events
	function abort(node:Node, ?eventProperties:EventProperties):Void;
	function canPlay(node:Node, ?eventProperties:EventProperties):Void;
	function canPlayThrough(node:Node, ?eventProperties:EventProperties):Void;
	function durationChange(node:Node, ?eventProperties:EventProperties):Void;
	function emptied(node:Node, ?eventProperties:EventProperties):Void;
	function encrypted(node:Node, ?eventProperties:EventProperties):Void;
	function ended(node:Node, ?eventProperties:EventProperties):Void;
	function loadedData(node:Node, ?eventProperties:EventProperties):Void;
	function loadedMetadata(node:Node, ?eventProperties:EventProperties):Void;
	function loadStart(node:Node, ?eventProperties:EventProperties):Void;
	function pause(node:Node, ?eventProperties:EventProperties):Void;
	function play(node:Node, ?eventProperties:EventProperties):Void;
	function playing(node:Node, ?eventProperties:EventProperties):Void;
	function progress(node:Node, ?eventProperties:EventProperties):Void;
	function rateChange(node:Node, ?eventProperties:EventProperties):Void;
	function seeked(node:Node, ?eventProperties:EventProperties):Void;
	function seeking(node:Node, ?eventProperties:EventProperties):Void;
	function stalled(node:Node, ?eventProperties:EventProperties):Void;
	function suspend(node:Node, ?eventProperties:EventProperties):Void;
	function timeUpdate(node:Node, ?eventProperties:EventProperties):Void;
	function volumeChange(node:Node, ?eventProperties:EventProperties):Void;
	function waiting(node:Node, ?eventProperties:EventProperties):Void;
	// Image Events
	function load(node:Node, ?eventProperties:EventProperties):Void;
	function error(node:Node, ?eventProperties:EventProperties):Void;
	// Animation Events
	function animationStart(node:Node, ?eventProperties:EventProperties):Void;
	function animationEnd(node:Node, ?eventProperties:EventProperties):Void;
	function animationIteration(
		node:Node,
		?eventProperties:EventProperties
	):Void;
	// Transition Events
	function transitionEnd(node:Node, ?eventProperties:EventProperties):Void;
	// pointer events
	function pointerOver(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function pointerEnter(node:Node, ?eventProperties:EventProperties):Void;
	function pointerDown(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function pointerMove(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function pointerUp(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function pointerCancel(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function pointerOut(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function pointerLeave(node:Node, ?eventProperties:EventProperties):Void;
	function gotPointerCapture(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	function lostPointerCapture(
		node:Node,
		?eventProperties:ComposableEventProperties
	):Void;
	// history events
	function popState(node:Node, ?eventProperties:EventProperties):Void;
}

typedef EventProperties = {bubbles:Bool, cancelable:Bool};

typedef ComposableEventProperties = {
	bubbles:Bool,
	cancelable:Bool,
	composed:Bool
};
