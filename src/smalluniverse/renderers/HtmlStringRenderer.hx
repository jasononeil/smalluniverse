package smalluniverse.renderers;

import smalluniverse.SmallUniverse;
import haxe.ds.Option;
import StringBuf;

using tink.CoreApi;

final selfClosingTags = [
	"area",
	"base",
	"br",
	"col",
	"command",
	"embed",
	"hr",
	"img",
	"input",
	"keygen",
	"link",
	"menuitem",
	"meta",
	"param",
	"source",
	"track",
	"wbr",
];

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
			if (children.length == 0 && selfClosingTags.contains(tag)) {
				html.add('>');
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
		case Multiple(attrs):
			final strings = attrs
					.map(stringifyAttr)
					.filter(option -> option.match(Some(_)))
					.map(option -> option.sure());
			return strings.length > 0 ? Some(strings.join(" ")) : None;
		case Property(_, _), Event(_, _), Key(_), Hook(_):
			// we only stringify attributes
			return None;
	}
}
