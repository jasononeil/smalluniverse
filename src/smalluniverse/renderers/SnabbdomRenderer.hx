package smalluniverse.renderers;

import smalluniverse.clients.Browser.triggerAction;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import smalluniverse.SmallUniverse.Html;
import smalluniverse.SmallUniverse.HookType;
import js.html.Node;
import js.html.Element;
import js.html.Event;
import js.Lib.undefined;
import Snabbdom;
import Snabbdom.h;

class SnabbdomRenderer {
	var patch:Null<PatchFunction>;
	var previousVNode:Null<VNode>;

	public function new() {}

	public function init(node:Node) {
		patch = Snabbdom.init([
			Snabbdom.attributesModule,
			Snabbdom.propsModule,
			Snabbdom.eventListenersModule
		]);
		previousVNode = Snabbdom.toVNode(node);
	}

	public function update(html:Html<Dynamic>) {
		final newNode = htmlToVNode(html);
		if (patch == null || previousVNode == null) {
			throw 'update() called before init()';
		}

		patch(previousVNode, newNode);
		this.previousVNode = newNode;
	}

	public function destroy() {
		if (patch == null || previousVNode == null) {
			throw 'destroy() called before init()';
		}

		// Replace the rendered view with an empty comment.
		patch(previousVNode, Snabbdom.h('!', {}, []));
	}
}

function htmlToVNode(html:Html<Dynamic>):VNode {
	switch html.type {
		case Element(tag, attrs, children):
			final allHooks = [];
			final data = {
				attrs: new DynamicAccess(),
				props: new DynamicAccess(),
				on: new DynamicAccess(),
				hook: null,
				key: null,
			};
			for (attr in attrs) {
				switch attr {
					case Attribute(name, value):
						data.attrs[name] = value;
					case BooleanAttribute(name, value):
						// Snabbdom looks for truthy/falsey values.
						if (value) {
							data.attrs.set(name, name);
						}
					case Property(name, value):
						data.props[name] = value;
					case Event(eventType, eventHandler):
						data.on[eventType] = (e:Event) -> {
							switch eventHandler(e) {
								case Some(actionValue):
									triggerAction(actionValue);
								case None:
							}
						};
					case Hook(hookType):
						allHooks.push(hookType);
					case Key(key):
						data.key = key;
				}
			}

			data.hook = setupHooks(allHooks);

			var childVNodes = [];
			for (child in children) {
				for (vNode in htmlToVNodeChild(child)) {
					childVNodes.push(vNode);
				}
			}

			return h(tag, data, childVNodes);
		case Text(text):
			if (text.length == 0) {
				return h('!', undefined, '');
			}
			return Snabbdom.vnode(
				undefined,
				undefined,
				undefined,
				text,
				undefined
			);
		case Comment(text):
			return h('!', undefined, text);
		case Fragment(nodes):
			if (nodes.length == 0) {
				return h('!', undefined, '');
			}
			// Snabbdom can't render multiple nodes as the top level of the virtual dom.
			// We're wrapping in a div as a hacky workaround (and alternative to dropping content or throwing an exception)
			final children:Array<EitherType<VNode, String>> = [];
			children.push(
				h(
					"!",
					undefined,
					"This div wrapper added by SmallUniverse because Snabbdom requires a single element (not multiple nodes) at the top of the virtual dom tree."
				)
			);
			for (htmlNode in nodes) {
				for (vnode in htmlToVNodeChild(htmlNode)) {
					children.push(vnode);
				}
			}
			return h('div', {}, children);
	}
}

/** Snabbdom has slightly different ways of creating vnode children as compared to root nodes. **/
function htmlToVNodeChild(html:Html<Dynamic>):Array<EitherType<VNode, String>> {
	switch html.type {
		case Element(tag, attrs, children):
			return [htmlToVNode(html)];
		case Text(text):
			if (text.length == 0) {
				return [];
			}
			// Child text nodes are created as a plain string.
			return [text];
		case Comment(text):
			return [htmlToVNode(html)];
		case Fragment(nodes):
			final vNodes = [];
			for (node in nodes) {
				for (vNode in htmlToVNodeChild(node)) {
					vNodes.push(vNode);
				}
			}
			return vNodes;
	}
}

function setupHooks<Action>(
	allHooksForNode:Array<HookType<Action>>
):SnabbdomModule {
	final initHooks = [];
	final insertHooks = [];
	final removeHooks = [];
	final destroyHooks = [];

	for (hookType in allHooksForNode) {
		switch hookType {
			case Init(callback):
				initHooks.push(callback);
			case Insert(callback):
				insertHooks.push(callback);
			case Remove(callback):
				removeHooks.push(callback);
			case Destroy(callback):
				destroyHooks.push(callback);
		}
	}

	function combineHooks<T>(hooks:Array<Any>, runAllHooksFn:T):T {
		if (hooks.length == 0) {
			return js.Lib.undefined;
		}
		return runAllHooksFn;
	}

	return {
		init: combineHooks(initHooks, (vNode:VNode) -> {
			for (initHook in initHooks) {
				initHook({
					triggerAction: triggerAction
				});
			}
		}),
		insert: combineHooks(insertHooks, (vNode:VNode) -> {
			for (insertHook in insertHooks) {
				insertHook({
					domElement: getDomElement(vNode),
					triggerAction: triggerAction
				});
			}
		}),
		remove: combineHooks(
			removeHooks,
			(vNode:VNode, removeCallback:() -> Void) -> {
				var hooksCompleted = 0;
				function checkIfAllComplete() {
					if (hooksCompleted == removeHooks.length) {
						removeCallback();
					}
				}
				checkIfAllComplete();
				for (removeHook in removeHooks) {
					removeHook({
						domElement: getDomElement(vNode),
						triggerAction: triggerAction,
						removeCallback: () -> {
							hooksCompleted++;
							checkIfAllComplete();
						}
					});
				}
			}
		),
		destroy: combineHooks(destroyHooks, (vNode:VNode) -> {
			for (destroyHook in destroyHooks) {
				destroyHook({
					domElement: getDomElement(vNode),
					triggerAction: triggerAction
				});
			}
		}),
	}
}

private function getDomElement(vNode:VNode):Element {
	final node = vNode.elm;
	if (node == null) {
		throw 'Expected vNode to have `.elm` property containing DOM Node, but was null';
	}
	final elm = @:nullSafety(Off) Std.downcast(node, js.html.Element);
	if (elm == null) {
		throw 'Expected vNode to have `.elm` property containing DOM Element, but was a different kind of node: ${node.nodeType}';
	}
	return elm;
}
