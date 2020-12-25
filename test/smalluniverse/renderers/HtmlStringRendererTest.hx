package smalluniverse.renderers;

import smalluniverse.DOM.comment;
import smalluniverse.DOM.element;
import smalluniverse.DOM.text;
import tink.unit.Assert.*;
import smalluniverse.renderers.HtmlStringRenderer.stringifyHtml;

class HtmlStringRendererTest {
	public function new() {}

	public function testEmptyString()
		return assert(stringifyHtml("") == "");

	public function testEmptyArray()
		return assert(stringifyHtml([]) == "");

	public function testText()
		return assert(stringifyHtml(text("Hello!")) == "Hello!");

	public function testTextWithHtml()
		return assert(stringifyHtml(text("Love! <3")) == "Love! &lt;3");

	public function testComment()
		return assert(stringifyHtml(comment("Hello!")) == "<!--Hello!-->");

	public function testCommentWithHtml()
		return assert(stringifyHtml(comment("Look! -->")) == "<!--Look! --&gt;-->");

	public function testEmptyBrElement()
		return assert(stringifyHtml(element("br", [], [])) == "<br/>");

	public function testEmptyDivElement()
		return assert(stringifyHtml(element("div", [], [])) == "<div/>");

	public function testEmptyElementWithAttrs()
		return assert(stringifyHtml(element("hr", [Attribute("class", "divider")], [])) == "<hr class=\"divider\"/>");

	public function testMultipleAttrs()
		return assert(stringifyHtml(element("p", [Attribute("class", "lede"), Attribute("id", "intro")], [])) == "<p class=\"lede\" id=\"intro\"/>");

	public function testAttrsWithHtml()
		return assert(stringifyHtml(element("p", [Attribute("class", 'lede">Hack'), Attribute("id", "intro'>Hack")],
			[])) == '<p class="lede&quot;&gt;Hack" id="intro&#039;&gt;Hack"/>');

	public function testChildren()
		return assert(stringifyHtml(element("p", [], [text("Hello"), comment("Cruel"), text("World")])) == "<p>Hello<!--Cruel-->World</p>");

	public function testRecursion()
		return assert(stringifyHtml(element("p", [],
			[text("Hello "), element("span", [], [text("Kind")]), text(" World")])) == "<p>Hello <span>Kind</span> World</p>");

	public function testFragment()
		return assert(stringifyHtml(["Kind Regards,", element("br", [], []), "Jason"]) == "Kind Regards,<br/>Jason");
}
