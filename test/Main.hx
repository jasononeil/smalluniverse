import tink.unit.*;
import tink.testrunner.*;
import smalluniverse.renderers.HtmlStringRendererTest;
import smalluniverse.SmallUniverseTest;

function main() {
	trace("Small Universe");
	final allTests = TestBatch.make([new HtmlTest(), new HtmlStringRendererTest()]);
	Runner.run(allTests).handle(Runner.exit);
}
