package smalluniverse;

import haxe.ds.Option;

interface Router {
	function routeToUri<PageParams>(page:Page<Dynamic, PageParams, Dynamic>, params:PageParams):Option<String>;
	function uriToRoute<PageParams>(uri:String):Option<{page:Page<Dynamic, PageParams, Dynamic>, params:PageParams}>;
}

interface Projection<Action> {
	function handleAction(action:Action):Void;
	// Projection lifecycle methods?
	// version: Int;
	// state: Starting, Ready, Stalled
}

interface CommandHandler<Action> extends Projection<Action> {
	// Does this as a separate method make sense? What if we want to use a DB transaction?
	// Perhaps a CommandHandler is purely a projection, and `handleAction()` rejects if not allowed?
	function allowAction(action:Action):Bool;
}

interface PageApi<Action, PageParams, PageData> {
	function getPageData(pageParams:PageParams):PageData;
	// Optional: we could use this for websocket updates.
	function pageDataShouldUpdate(pageParams:PageParams, action:Action):Bool;
}

interface PageView<Action, PageData> {
	function render(data:PageData):Html<Action>;
}

enum Page<Action, PageParams, PageData> {
	// Should these be instances or classes that we instantiate as needed?
	Page(view:PageView<Action, PageData>, api:PageApi<Action, PageParams, PageData>);
}

interface Component<Props, State, InnerAction, OuterAction> {
	function render(props:Props, state:State):Html<InnerAction>;
	function defaultState(props:Props):State;
	function update(currentState:State, action:InnerAction):{newState:State, outerAction:Option<OuterAction>}
}

abstract Html<Action>(HtmlType<Action>) from HtmlType<Action> to HtmlType<Action> {
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

enum HtmlType<Action> {
	Element(tag:String, attrs:Array<HtmlAttribute<Action>>, children:Html<Action>);
	Text(text:String);
	Comment(text:String);
	Fragment(nodes:Array<Html<Action>>);
	// TODO: Component
}

enum HtmlAttribute<Action> {
	Attribute(name:String, value:String);
	Property(name:String, value:Any);
	Event(on:String, fn:() -> Option<Action>);
}

function mapHtml<InnerAction, OuterAction>(html:Html<InnerAction>, convert:InnerAction->Option<OuterAction>):Html<OuterAction> {
	switch html {
		case Element(tag, attrs, children):
			return Element(tag, attrs.map(a -> mapAttr(a, convert)), mapHtml(children, convert));
		case Text(text):
			return Text(text);
		case Comment(text):
			return Comment(text);
		case Fragment(nodes):
			return Fragment(nodes.map(n -> mapHtml(n, convert)));
	}
}

function mapAttr<InnerAction, OuterAction>(attr:HtmlAttribute<InnerAction>, convert:InnerAction->Option<OuterAction>):HtmlAttribute<OuterAction> {
	switch attr {
		case Attribute(name, value):
			return Attribute(name, value);
		case Property(name, value):
			return Property(name, value);
		case Event(on, innerFn):
			function outerFn() {
				switch innerFn() {
					case Some(v):
						return convert(v);
					case None:
						return None;
				}
			}
			return Event(on, outerFn);
	}
}
