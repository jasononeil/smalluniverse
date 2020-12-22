package smalluniverse;

import smalluniverse.SmallUniverse;

inline function element<Action>(tag:String, attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return Element(tag, attrs, children);

inline function text<Action>(text:String)
	return Text(text);

inline function comment<Action>(text:String)
	return Comment(text);

// TODO: add some better typing for attributes

inline function div<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("div", attrs, children);

inline function span<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("span", attrs, children);

inline function h1<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("h1", attrs, children);

inline function h2<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("h2", attrs, children);

inline function h3<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("h3", attrs, children);

inline function h4<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("h4", attrs, children);

inline function h5<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("h5", attrs, children);

inline function h6<Action>(attrs:Array<HtmlAttribute<Action>>, children:Array<Html<Action>>)
	return element("h6", attrs, children);
