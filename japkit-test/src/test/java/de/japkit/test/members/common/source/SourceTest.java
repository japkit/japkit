package de.japkit.test.members.common.source;

import static java.util.Arrays.asList;

/**
 * Tests if all expected artifacts have been generated.
 */
public class SourceTest {

	public void test() {
		SourceExampleGen gen = new SourceExampleGen();
		asList(gen.sourceExample, gen.srcField1Copy1, gen.srcField1Copy2, gen.srcField1Copy3, gen.srcField1Copy4, gen.srcField1Copy5,
				gen.srcField1Copy6, gen.srcField2Copy1, gen.srcField2Copy2, gen.srcField2Copy3, gen.srcField2Copy4, gen.srcField2Copy5,
				gen.srcField2Copy6);
		gen.setSrcField1("");
		gen.setSrcField2(1);
	}

}
