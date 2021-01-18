package smalluniverse.renderers;

import haxe.DynamicAccess;
import haxe.extern.EitherType;
import smalluniverse.SmallUniverse.Html;
import js.html.Node;
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
		final _prevNode = this.previousVNode;
		final _patch = this.patch;
		if (_patch == null || _prevNode == null) {
			throw 'update() called before init()';
		}

		final newNode = htmlToVNode(html);
		_patch(_prevNode, newNode);
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
						data.attrs[name] = value ? "true" : "";
					case Property(name, value):
						data.props[name] = value;
					case Event(on, fn):
						// TODO: figure out our plan for event handlers.
						data.on[on] = fn;
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
			return h(undefined, undefined, text);
		case Comment(text):
			return h('!', undefined, text);
		case Fragment(nodes):
			// Snabbdom can't render multiple elements as the top level of the virtual dom.
			// For now I'm treating this as a fatal error - one alternative would be wrapping them in a <div>
			throw 'Snabbdom does not allow rendering a Fragment at the top of your render tree, please render a single element with children.';
	}
}

/** Snabbdom has slightly different ways of creating vnode children as compared to root nodes. **/
function htmlToVNodeChild(html:Html<Dynamic>):Array<EitherType<VNode, String>> {
	switch html.type {
		case Element(tag, attrs, children):
			return [htmlToVNode(html)];
		case Text(text):
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
