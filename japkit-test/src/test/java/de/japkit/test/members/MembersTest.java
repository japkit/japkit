package de.japkit.test.members;

import static java.util.Arrays.asList;
import static org.junit.Assert.assertEquals;

import org.junit.Test;

import de.japkit.test.members.MembersExampleGen.SomeInnerClass;

/**
 * Tests if all expected artifacts have been generated.
 */
public class MembersTest {

	@Test
	public void test() {
		MembersExampleGen gen = new MembersExampleGen("foo", 1);
		asList(gen.fixedField, gen.fieldA, gen.fieldB);
		gen.fixedMethod("bar");
		gen.methodA();
		gen.methodB();
		SomeInnerClass innerClass = gen.new SomeInnerClass("zzz");
		innerClass.new SomeInnerInnerClass();

		gen.fixedField = "0";
		gen.fieldA = "1";
		gen.fieldB = "2";
		assertEquals("toString", "MembersExample {fixedField=0, fieldA=1, fieldB=2}", gen.toString());
	}

}
