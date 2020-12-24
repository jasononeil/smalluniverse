import tink.unit.*;
import tink.unit.Assert.*;
import tink.testrunner.*;
import smalluniverse.SmallUniverse;

function main() {
	trace("Small Universe");
	Runner.run(TestBatch.make([new Test(),])).handle(Runner.exit);
}

class Test {
	public function new() {}

	public function test()
		return assert(true);
}
