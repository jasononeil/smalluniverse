package smalluniverse.renderers;

import js.html.VideoElement;
import smalluniverse.renderers.SnabbdomRenderer.htmlToVNode;
import Snabbdom.VNode;
import tink.unit.Assert;
import smalluniverse.DOM.comment;
import smalluniverse.DOM.element;
import smalluniverse.DOM.text;
import smalluniverse.SmallUniverse;
import tink.unit.Assert.*;
import tink.unit.AssertionBuffer;
import js.html.Element;
import smalluniverse.testing.SnabbdomTestingLibrary;
import smalluniverse.testing.SnabbdomTestingLibrary.getByText;
import smalluniverse.testing.SnabbdomTestingLibrary.fireEvent;

using tink.CoreApi;

final jsdomGlobal = js.Lib.require("jsdom-global");

function render(vNode:VNode) {
	function doRender() {
		final renderer = new SnabbdomRenderer();
		final container = js.Browser.document.createElement("div");
		renderer.init(container);
		final patchFn = @:privateAccess renderer.patch;
		if (patchFn == null) {
			throw "patch function was null";
		}
		final renderFn = SnabbdomTestingLibrary.makeRender({patch: patchFn})();
		return renderFn(vNode);
	}

	if (js.Lib.typeof(js.Browser.window) == "undefined") {
		final jsdomCleanup = jsdomGlobal();
		final result = doRender();
		jsdomCleanup();
		return result;
	} else {
		return doRender();
	}
}

class SnabbdomRendererTest {
	public function new() {}

	function getRenderedHtml(html:Html<Dynamic>):String {
		return getRenderedContainer(html).innerHTML;
	}

	function getRenderedContainer(html:Html<Dynamic>):Element {
		return render(htmlToVNode(html)).container;
	}

	public function testEmptyString()
		return assert(
			getRenderedHtml("") == "<!---->",
			"should render an empty comment"
		);

	public function testEmptyArray()
		return assert(
			getRenderedHtml([]) == "<!---->",
			"should render an empty comment"
		);

	public function testText()
		return assert(getRenderedHtml(text("Hello!")) == "Hello!");

	public function testTextWithHtml()
		return assert(getRenderedHtml(text("Love! <3")) == "Love! &lt;3");

	public function testComment()
		return assert(getRenderedHtml(comment("Hello!")) == "<!--Hello!-->");

	public function testCommentWithHtml() {
		final container = getRenderedContainer(comment("Look! -->"));
		final asserts = new AssertionBuffer();
		asserts.assert(container.childNodes.length == 1, "there is one child");
		asserts.assert(
			container.childNodes.item(0).nodeType == 8,
			"it is a comment node (type==8)"
		);
		asserts.assert(
			container.childNodes.item(0).textContent == "Look! -->",
			"It has the correct text"
		);
		return asserts.done();
	}

	public function testEmptyBrElement()
		return assert(getRenderedHtml(element("br", [], [])) == "<br>");

	public function testEmptyDivElement()
		return assert(getRenderedHtml(element("div", [], [])) == "<div></div>");

	public function testEmptyElementWithAttrs()
		return assert(getRenderedHtml(element("hr", [
			Attribute("class", "divider")
		], [])) == "<hr class=\"divider\">");

	public function testMultipleAttrs()
		return assert(getRenderedHtml(element("p", [
			Attribute("class", "lede"),
			Attribute("id", "intro")
		], [])) == "<p class=\"lede\" id=\"intro\"></p>");

	public function testAttrsWithHtml() {
		final asserts = new AssertionBuffer();
		final container = getRenderedContainer(element("p", [
			Attribute("class", 'lede">Hack'),
			Attribute("id", "intro'>Hack")
		], []));
		asserts.assert(container.childNodes.length == 1);
		final elm = container.firstElementChild;
		asserts.assert(elm.nodeName.toLowerCase() == "p");
		asserts.assert(elm.getAttribute("class") == 'lede">Hack');
		asserts.assert(elm.getAttribute("id") == "intro'>Hack");
		return asserts.done();
	}

	public function testBooleanAttrTrue() {
		// Note: Snabbdom seems to only work creating `disabled="somevalue"` rather than `disabled`.
		// This is different to our HTML String renderer but shouldn't be different in practice.
		return assert(getRenderedHtml(element("button", [
			BooleanAttribute("disabled", true)
		], [])) == '<button disabled="disabled"></button>');
	}

	public function testBooleanAttrFalse()
		return assert(getRenderedHtml(element("button", [
			BooleanAttribute("disabled", false)
		], [])) == "<button></button>");

	public function testPropertiesThatAreAttributes() {
		return assert(getRenderedHtml(element("p", [
			Property("className", "lede"),
			Property("title", "Welcome Paragraph")
		], [])) == '<p class="lede" title="Welcome Paragraph"></p>');
	}

	public function testPropertiesThatAreNotAttributes() {
		final asserts = new AssertionBuffer();
		final video = element("video", [Property("currentTime", 35)], []);
		final container = getRenderedContainer(video);
		asserts.assert(getRenderedHtml(video) == '<video></video>');
		asserts.assert(container.childNodes.length == 1);
		asserts.assert(container.firstChild.nodeName.toLowerCase() == "video");
		final videoElement:VideoElement = cast container.firstChild;
		asserts.assert(videoElement.currentTime == 35);

		return asserts.done();
	}

	public function testEvents() {
		final asserts = new AssertionBuffer();

		var called = 0;
		final btn = element("button", [Event("click", (e) -> {
			called++;
			return None;
		})], ["My button"]);
		final container = getRenderedContainer(btn);
		final renderedBtn = getByText(container, "My button");

		fireEvent.click(renderedBtn);
		asserts.assert(called == 1);

		fireEvent.click(renderedBtn);
		asserts.assert(called == 2);

		return asserts.done();
	}

	public function testMultipleAttrTypes() {
		// Note: in our HTML String Renderer only attributes are used, properties are ignored.
		// So in the equivalent test for that renderer, className is "primary", here it is "primary-2"
		// as the Property("className", "primary-2") declaration overrides the earlier Attribute("class", "primary")
		return assert(getRenderedHtml(element("button", [
			Attribute("class", "primary"),
			BooleanAttribute("disabled", false),
			BooleanAttribute("active", true),
			Attribute("id", "cta"),
			Property("className", "primary-2"),
			Event("click", (e) -> None)
		], [])) == '<button class="primary-2" active="active" id="cta"></button>');
	}

	public function testChildren()
		return assert(getRenderedHtml(element("p", [], [
			text("Hello"),
			comment("Cruel"),
			text("World")
		])) == "<p>Hello<!--Cruel-->World</p>");

	public function testRecursion()
		return assert(getRenderedHtml(element("p", [], [
			text("Hello "),
			element("span", [], [
				text("Kind")
			]),
			text(" World")
		])) == "<p>Hello <span>Kind</span> World</p>");

	public function testFragment() {
		// Snabbdom can't render a fragment as the top level, so we wrap it in a div.
		return assert(getRenderedHtml([
			"Kind Regards,",
			element("br", [], []),
			"Jason"
		]) == "<div><!--This div wrapper added by SmallUniverse because Snabbdom requires a single element (not multiple nodes) at the top of the virtual dom tree.-->Kind Regards,<br>Jason</div>");
	}

	// AND THEN, WE SHOULD PROBABLY CONSIDER SOME SNABBDOM SPECIFIC TESTS
}
