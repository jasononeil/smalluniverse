package smalluniverse.renderers;

import js.html.Element;
import js.Browser.document;
import js.html.InputElement;
import js.html.VideoElement;
import smalluniverse.DOM.comment;
import smalluniverse.DOM.element;
import smalluniverse.DOM.text;
import smalluniverse.SmallUniverse;
import tink.unit.Assert.*;
import tink.unit.AssertionBuffer;
import smalluniverse.testing.DomTestingLibrary;
import smalluniverse.testing.DomTestingLibrary.getByText;
import smalluniverse.testing.DomTestingLibrary.getByTestId;
import smalluniverse.testing.DomTestingLibrary.queryAllByText;
import smalluniverse.testing.DomTestingLibrary.fireEvent;

using tink.CoreApi;

function getRenderer() {
	final container = document.createElement("main");
	final initial = document.createElement("div");
	container.appendChild(initial);

	final renderer = new SnabbdomRenderer();
	renderer.init(initial);
	return {
		container: container,
		render: renderer.update
	}
}

function render(htmlVNodes:Html<Dynamic>) {
	final result = getRenderer();
	final container = result.container;
	final render = result.render;
	render(htmlVNodes);
	return container;
}

class SnabbdomRendererTest {
	public function new() {}

	@:setup
	public function setup() {
		DomTestingLibrary.setupJsdom();
		return tink.core.Promise.NOISE;
	}

	function getRenderedHtml(html:Html<Dynamic>):String {
		return render(html).innerHTML;
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
		final container = render(comment("Look! -->"));
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
		final container = render(element("p", [
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
		final container = render(video);
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
		final container = render(btn);
		final renderedBtn = getByText(container, "My button");

		fireEvent.click(renderedBtn);
		asserts.assert(called == 1);

		fireEvent.click(renderedBtn);
		asserts.assert(called == 2);

		return asserts.done();
	}

	public function testsHook() {
		final asserts = new AssertionBuffer();

		final result = getRenderer();
		final container = result.container;
		final render = result.render;

		final hookCalls = [];
		final removeTrigger = Future.trigger();

		function createSpan(name:String) {
			return element("span", [Hook(Init(args -> {
				hookCalls.push('$name init');
				return None;
			})), Hook(
				Insert(args -> hookCalls.push('$name insert'))
			), Hook(Remove(args -> {
				args.removeCallback();
				hookCalls.push('$name remove');
				})), Hook(
				Destroy(args -> hookCalls.push('$name destroy'))
				),], name);
		}
		function createDiv(children:Html<Any>) {
			return element("div", [Hook(Init(args -> {
				hookCalls.push("div init");
				return Some(() -> hookCalls.push("div init cleanup"));
			})), Hook(
				Insert(args -> hookCalls.push("div insert"))
			), Hook(Remove(args -> {
				removeTrigger.asFuture().handle(_ -> args.removeCallback());
				hookCalls.push("div remove");
				})), Hook(Destroy(args -> hookCalls.push("div destroy"))),], [
				children
				]);
		}

		render(createDiv([createSpan("span1"), createSpan("span2")]));

		asserts.assert(hookCalls.length == 6);
		asserts.assert(hookCalls[0] == "div init");
		asserts.assert(hookCalls[1] == "span1 init");
		asserts.assert(hookCalls[2] == "span2 init");
		asserts.assert(hookCalls[3] == "span1 insert");
		asserts.assert(hookCalls[4] == "span2 insert");
		asserts.assert(hookCalls[5] == "div insert");

		render(createDiv([createSpan("span1")]));

		asserts.assert(hookCalls.length == 8);
		asserts.assert(hookCalls[6] == "span2 destroy");
		asserts.assert(hookCalls[7] == "span2 remove");
		asserts.assert(queryAllByText(container, "span1").length == 1);
		asserts.assert(queryAllByText(container, "span2").length == 0);

		render(element("span", [], "replacement"));

		asserts.assert(hookCalls.length == 12);

		// the destroy and remove hooks are called
		asserts.assert(hookCalls[8] == "div init cleanup");
		asserts.assert(hookCalls[9] == "div destroy");
		asserts.assert(hookCalls[10] == "span1 destroy");
		asserts.assert(hookCalls[11] == "div remove");

		// and both the new element and old element are visible
		asserts.assert(queryAllByText(container, "span1").length == 1);
		asserts.assert(queryAllByText(container, "span2").length == 0);
		asserts.assert(queryAllByText(container, "replacement").length == 1);

		// until we trigger our removeCallback
		removeTrigger.trigger(Noise);
		asserts.assert(queryAllByText(container, "span1").length == 0);
		asserts.assert(queryAllByText(container, "span2").length == 0);
		asserts.assert(queryAllByText(container, "replacement").length == 1);

		// Other things it would be good to test:
		// Multiple "remove" hooks wait for all to trigger
		// "init" and "insert" hook are called even when hydrating a server rendered view

		return asserts.done();
	}

	public function testKey() {
		// To test this, lets create two inputs.
		// Emulate typing into one of them (or at least setting a value).
		// Then reorder them and see if the value is preserved.
		// This demonstrates that the node was not recreated even when the order changed.

		final asserts = new AssertionBuffer();

		final result = getRenderer();
		final container = result.container;
		final render = result.render;

		final input1Html = element("input", [Key("1")], []);
		final input2Html = element("input", [Key("2")], []);

		final form = element("form", [Attribute("data-testid", "form")], [
			input1Html,
			input2Html
		]);
		render(form);

		var form = getByTestId(container, "form");
		var input1:InputElement = cast form.children[0];
		var input2:InputElement = cast form.children[1];

		input1.value = "typing...";
		asserts.assert(input1.value == "typing...");
		asserts.assert(input2.value == "");

		final formWithReorderedInputs = element("form", [
			Attribute("data-testid", "form")
		], [
			input2Html,
			input1Html
		]);
		render(formWithReorderedInputs);

		form = getByTestId(container, "form");
		input1 = cast form.children[0];
		input2 = cast form.children[1];

		asserts.assert(input1.value == "");
		asserts.assert(input2.value == "typing...");

		return asserts.done();
	}

	public function testMultiple() {
		final asserts = new AssertionBuffer();
		final video = element("video", [
			BooleanAttribute("disabled", true),
			Multiple([
				Attribute("class", "my-css-class"),
				Attribute("id", "my-btn"),
				Property("currentTime", 35)
			])
		], []);
		final container = render(video);

		asserts.assert(
			getRenderedHtml(
				video
			) == '<video disabled="disabled" class="my-css-class" id="my-btn"></video>'
		);
		final videoElement:VideoElement = cast container.firstChild;
		asserts.assert(videoElement.currentTime == 35);
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
