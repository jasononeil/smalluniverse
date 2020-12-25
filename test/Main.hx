import tink.unit.*;
import tink.testrunner.*;
import smalluniverse.SmallUniverseTest;

function main() {
	trace("Small Universe");
	final allTests = TestBatch.make([new HtmlTest()]);
	Runner.run(allTests).handle(Runner.exit);
}
