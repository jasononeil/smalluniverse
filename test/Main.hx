import tink.unit.*;
import tink.testrunner.*;
import smalluniverse.renderers.HtmlStringRendererTest;
import smalluniverse.SmallUniverseTest;
import smalluniverse.DOMTest;

function main() {
	trace("Small Universe");
	final allTests = TestBatch.make([new HtmlTest(), new ClassNameTest(), new HtmlStringRendererTest()]);
	Runner.run(allTests).handle(Runner.exit);
}
