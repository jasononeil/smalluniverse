package smalluniverse;

import smalluniverse.SmallUniverse;
import smalluniverse.DOM;
import tink.unit.Assert.*;

class ClassNameTest {
	public function new() {}

	public function testNothing() {
		final attr:HtmlAttribute<{}> = className();
		return assert(attr.match(Attribute("class", "")));
	}

	public function testSingle() {
		final attr:HtmlAttribute<{}> = className("button");
		return assert(attr.match(Attribute("class", "button")));
	}

	public function testMultiple() {
		final attr:HtmlAttribute<{}> = className(["reversed", "primary"]);
		return assert(attr.match(Attribute("class", "reversed primary")));
	}

	public function testToggle() {
		final attr:HtmlAttribute<{}> = className(["active" => true, "disabled" => false, "focus-visible" => true]);
		return assert(attr.match(Attribute("class", "active focus-visible")));
	}

	public function testCombination() {
		final attr:HtmlAttribute<{}> = className("button", ["reversed", "primary"], ["active" => true, "disabled" => false, "focus-visible" => true]);
		return assert(attr.match(Attribute("class", "button reversed primary active focus-visible")));
	}
}
