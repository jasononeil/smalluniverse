package smalluniverse;

import smalluniverse.SmallUniverse;
import haxe.ds.Option;

inline function element<Action>(tag:String, attrs:Array<HtmlAttribute<Action>>, children:Html<Action>):Html<Action>
	return Element(tag, attrs, children);

inline function text<Action>(text:String):Html<Action>
	return Text(text);

inline function comment<Action>(text:String):Html<Action>
	return Comment(text);

inline function attr<Action>(name:String, value:String):HtmlAttribute<Action>
	return Attribute(name, value);

inline function booleanAttribute<Action>(name:String, value:Bool):HtmlAttribute<Action>
	return BooleanAttribute(name, value);

inline function prop<Action>(name:String, value:Any):HtmlAttribute<Action>
	return Property(name, value);

inline function on<Action>(name:String, handler:() -> Option<Action>):HtmlAttribute<Action>
	return Event(name, handler); //

// ELEMENTS
//
// TODO: add some better typing for attributes
// We can probably auto-generate these in the same way Haxe's js.html.* is generated
// See https://github.com/HaxeFoundation/html-externs/

inline function div<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("div", attrs, children);

inline function span<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("span", attrs, children);

inline function h1<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("h1", attrs, children);

inline function h2<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("h2", attrs, children);

inline function h3<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("h3", attrs, children);

inline function h4<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("h4", attrs, children);

inline function h5<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("h5", attrs, children);

inline function h6<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("h6", attrs, children);

inline function main<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("main", attrs, children);

inline function header<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("header", attrs, children);

inline function article<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("article", attrs, children);

inline function section<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("section", attrs, children);

inline function nav<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("nav", attrs, children);

inline function ul<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("ul", attrs, children);

inline function ol<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("ol", attrs, children);

inline function li<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("li", attrs, children);

inline function a<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("a", attrs, children);

inline function button<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("button", attrs, children);

inline function label<Action>(attrs:Array<HtmlAttribute<Action>>, children:Html<Action>)
	return element("label", attrs, children);

inline function input<Action>(attrs:Array<HtmlAttribute<Action>>)
	return element("input", attrs, []);

inline function inputText<Action>(attrs:Array<HtmlAttribute<Action>>)
	return input([type("text")].concat(attrs));

inline function checkbox<Action>(attrs:Array<HtmlAttribute<Action>>)
	return input([type("checkbox")].concat(attrs));

inline function radio<Action>(attrs:Array<HtmlAttribute<Action>>)
	return input([type("radio")].concat(attrs));

inline function link<Action>(attrs:Array<HtmlAttribute<Action>>, content:String = "")
	return element("link", attrs, content);

inline function style<Action>(attrs:Array<HtmlAttribute<Action>>, content:String = "")
	return element("style", attrs, content);

inline function script<Action>(attrs:Array<HtmlAttribute<Action>>, content:String = "")
	return element("script", attrs, content);

/** A small helper to add inline CSS. **/
inline function css<Action>(content:String = "")
	return style([type("text/css")], content);

//
// Attributes
//
function className<Action>(?single:String, ?multiple:Array<String>, ?toggles:Map<String, Bool>):HtmlAttribute<Action> {
	final attributeList = [];
	if (single != null) {
		attributeList.push(single);
	}
	if (multiple != null) {
		for (cls in multiple) {
			attributeList.push(cls);
		}
	}
	if (toggles != null) {
		for (cls => enabled in toggles) {
			if (enabled) {
				attributeList.push(cls);
			}
		}
	}
	return attr("class", attributeList.join(" "));
}

inline function href<Action>(value:String):HtmlAttribute<Action>
	return attr("href", value);

inline function type<Action>(value:String):HtmlAttribute<Action>
	return attr("type", value);

inline function rel<Action>(value:String):HtmlAttribute<Action>
	return attr("rel", value);

inline function src<Action>(value:String):HtmlAttribute<Action>
	return attr("src", value);

inline function checked<Action>(value:Bool):HtmlAttribute<Action>
	return booleanAttribute("checked", value);

inline function disabled<Action>(value:Bool):HtmlAttribute<Action>
	return booleanAttribute("disabled", value);
