package smalluniverse.renderers;

import smalluniverse.clients.Browser.postAction;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import smalluniverse.SmallUniverse.Html;
import js.html.Node;
import js.html.Event;
import js.Lib.undefined;
import Snabbdom;
import Snabbdom.h;

class SnabbdomRenderer {
	var patch:Null<PatchFunction>;
	var previousVNode:Null<VNode>;

	public function new() {}

	public function init(node:Node) {
		patch = Snabbdom.init([Snabbdom.attributesModule, Snabbdom.propsModule, Snabbdom.eventListenersModule]);
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
			var data = {
				attrs: new DynamicAccess(),
				props: new DynamicAccess(),
				on: new DynamicAccess(),
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
									postAction(actionValue);
								case None:
							}
						};
				}
				// TODO: hooks.
				// TODO: key.
			}

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
			return Snabbdom.vnode(undefined, undefined, undefined, text, undefined);
		case Comment(text):
			return h('!', undefined, text);
		case Fragment(nodes):
			if (nodes.length == 0) {
				return h('!', undefined, '');
			}
			// Snabbdom can't render multiple nodes as the top level of the virtual dom.
			// We're wrapping in a div as a hacky workaround (and alternative to dropping content or throwing an exception)
			final children:Array<EitherType<VNode, String>> = [];
			children.push(h("!", undefined,
				"This div wrapper added by SmallUniverse because Snabbdom requires a single element (not multiple nodes) at the top of the virtual dom tree."));
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
