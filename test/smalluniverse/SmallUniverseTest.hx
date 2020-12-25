package smalluniverse;

import smalluniverse.SmallUniverse;
import tink.unit.Assert.*;

class HtmlTest {
	public function new() {}

	public function testStringCast() {
		final html:Html<{}> = "Hello";
		return assert(html.type.match(Text("Hello")));
	}

	public function testArrayCast() {
		final html:Html<{}> = [Text("Hello"), Comment("World")];
		return assert(html.type.match(Fragment([Text("Hello"), Comment("World")])));
	}

	public function testTypeCast() {
		final html:Html<{}> = Comment("World");
		return assert(html.type.match(Comment("World")));
	}

	public function testLengthOfSingleText() {
		final html:Html<{}> = Text("Hello");
		return assert(html.length == 1);
	}

	public function testLengthOfSingleComment() {
		final html:Html<{}> = Comment("World");
		return assert(html.length == 1);
	}

	public function testLengthOfSingleElement() {
		final html:Html<{}> = Element("p", [], []);
		return assert(html.length == 1);
	}

	public function testLengthOfSingleElementWithChildren() {
		final html:Html<{}> = Element("p", [], [Text("1"), Text("2")]);
		return assert(html.length == 1);
	}

	public function testLengthOfFragment() {
		final html:Html<{}> = Fragment([Text("1"), Comment("2")]);
		return assert(html.length == 2);
	}

	public function testLengthOfEmptyText() {
		final html:Html<{}> = Text("");
		return assert(html.length == 0);
	}

	public function testLengthOfEmptyFragment() {
		final html:Html<{}> = Fragment([]);
		return assert(html.length == 0);
	}

	public function testIteratorOfSingleText() {
		final html:Html<{}> = Text("Hello");
		return assert([for (node in html) node].length == 1);
	}

	public function testIteratorOfSingleComment() {
		final html:Html<{}> = Comment("World");
		return assert([for (node in html) node].length == 1);
	}

	public function testIteratorOfSingleElement() {
		final html:Html<{}> = Element("p", [], []);
		return assert([for (node in html) node].length == 1);
	}

	public function testIteratorOfSingleElementWithChildren() {
		final html:Html<{}> = Element("p", [], [Text("1"), Text("2")]);
		return assert([for (node in html) node].length == 1);
	}

	public function testIteratorOfFragment() {
		final html:Html<{}> = Fragment([Text("1"), Comment("2")]);
		return assert([for (node in html) node].length == 2);
	}

	public function testIteratorOfEmptyText() {
		final html:Html<{}> = Text("");
		return assert([for (node in html) node].length == 0);
	}

	public function testIteratorOfEmptyFragment() {
		final html:Html<{}> = Fragment([]);
		return assert([for (node in html) node].length == 0);
	}
}
