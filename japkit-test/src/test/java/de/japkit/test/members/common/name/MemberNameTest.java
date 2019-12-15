package de.japkit.test.members.common.name;

import static java.util.Arrays.asList;

/**
 * Tests if all expected artifacts have been generated.
 */
public class MemberNameTest {

	public void test() {
		MemberNameExampleGen gen = new MemberNameExampleGen();
		asList(gen.memberNameExample1, gen.memberNameExample2, gen.prefixMemberNameExample2, gen.memberNameExample3, gen.someString1,
				gen.someString2, gen.srcField1Copy, gen.srcField2Copy);
	}

}
