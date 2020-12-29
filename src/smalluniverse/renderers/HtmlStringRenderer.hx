package smalluniverse.renderers;

import smalluniverse.SmallUniverse;
import haxe.ds.Option;
import StringBuf;

function stringifyHtml(html:Html<Dynamic>):String {
	switch html {
		case Element(tag, attrs, children):
			final html = new StringBuf();
			html.add('<$tag');
			for (attr in attrs) {
				switch stringifyAttr(attr) {
					case Some(attrStr):
						html.add(' ' + attrStr);
					case None:
				}
			}
			if (children.length == 0) {
				html.add('/>');
			} else {
				html.add('>');
				for (child in children) {
					html.add(stringifyHtml(child));
				}
				html.add('</$tag>');
			}
			return html.toString();
		case Text(text):
			return StringTools.htmlEscape(text);
		case Comment(text):
			return '<!--${StringTools.htmlEscape(text)}-->';
		case Fragment(nodes):
			return [for (node in nodes) stringifyHtml(node)].join("");
	}
}

private function stringifyAttr(attr:HtmlAttribute<Dynamic>):Option<String> {
	switch attr {
		case Attribute(name, value):
			final escapedValue = StringTools.htmlEscape(value, true);
			return Some('$name="$escapedValue"');
		case BooleanAttribute(name, value):
			return value ? Some('$name') : None;
		case Property(name, value):
			// we only stringify attributes
			return None;
		case Event(on, fn):
			// we only stringify attributes
			return None;
	}
}
