import js.html.Node;
import haxe.extern.EitherType;

// Snabbdom doesn't have a single import, so I've got this class to gather the functions for easier access.
class Snabbdom {
	inline public static function init(
		modules:Array<SnabbdomModule>
	):PatchFunction
		return SnabbdomInit.init(modules);

	inline public static function h(
		tag:String,
		data:{},
		children:EitherType<String, Array<VNode>>
	):VNode
		return SnabbdomH.h(tag, data, children);

	inline public static function vnode(
		tag:String,
		data:{},
		children:EitherType<String, Array<VNode>>,
		text:Null<String>,
		elm:Node
	):VNode
		return SnabbdomVNode.vnode(tag, data, children, text, elm);

	inline public static function toVNode(node:Node):VNode
		return SnabbdomToVNode.toVNode(node);

	public static var propsModule(get, never):SnabbdomModule;

	public static var attributesModule(get, never):SnabbdomModule;

	public static var eventListenersModule(get, never):SnabbdomModule;

	inline static function get_propsModule()
		return SnabbdomProps.propsModule;

	inline static function get_attributesModule()
		return SnabbdomAttributes.attributesModule;

	inline static function get_eventListenersModule()
		return SnabbdomEventListeners.eventListenersModule;
}

typedef VNode = {
	var sel:Null<String>;
	var data:Null<Dynamic<Dynamic>>;
	var children:Null<Array<VNode>>;
	var text:Null<String>;
	var elm:Null<Node>;
	var key:Null<EitherType<String, Float>>;
}

typedef SnabbdomModule = {
	/** The patch process begins **/
	@:optional function pre():Void;

	/** a vnode has been added **/
	@:optional function init(vnode:VNode):Void;

	/** a DOM element has been created based on a vnode **/
	@:optional function create(emptyVnode:VNode, vnode:VNode):Void;

	/** an element has been inserted into the DOM **/
	@:optional function insert(vnode:VNode):Void;

	/** an element is about to be patched **/
	@:optional function prepatch(oldVnode:VNode, vnode:VNode):Void;

	/** an element is being updated **/
	@:optional function update(oldVnode:VNode, vnode:VNode):Void;

	/** an element has been patched **/
	@:optional function postpatch(oldVnode:VNode, vnode:VNode):Void;

	/** an element is directly or indirectly being removed **/
	@:optional function destroy(vnode:VNode):Void;

	/** an element is directly being removed from the DOM **/
	@:optional function remove(vnode:VNode, removeCallback:() -> Void):Void;

	/** the patch process is done **/
	@:optional function post():Void;
}

typedef PatchFunction = (old:EitherType<VNode, Node>, newVNode:VNode) -> Void;

@:js.import(@star 'snabbdom/build/package/init')
extern class SnabbdomInit {
	public static function init(modules:Array<SnabbdomModule>):PatchFunction;
}

@:js.import(@star 'snabbdom/build/package/h')
extern class SnabbdomH {
	public static function h(
		tag:String,
		data:{},
		children:EitherType<String, Array<VNode>>
	):VNode;
}

@:js.import(@star 'snabbdom/build/package/vnode')
extern class SnabbdomVNode {
	public static function vnode(
		tag:Null<String>,
		data:Null<{}>,
		children:Null<EitherType<String, Array<VNode>>>,
		text:Null<String>,
		elm:Null<Node>
	):VNode;
}

@:js.import(@star 'snabbdom/build/package/tovnode')
extern class SnabbdomToVNode {
	public static function toVNode(node:Node):VNode;
}

@:js.import(@star 'snabbdom/build/package/modules/props')
extern class SnabbdomProps {
	public static var propsModule:SnabbdomModule;
}

@:js.import(@star 'snabbdom/build/package/modules/attributes')
extern class SnabbdomAttributes {
	public static var attributesModule:SnabbdomModule;
}

@:js.import(@star 'snabbdom/build/package/modules/eventlisteners')
extern class SnabbdomEventListeners {
	public static var eventListenersModule:SnabbdomModule;
}
