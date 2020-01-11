package de.japkit.test.members.constructor;

import static junit.framework.Assert.assertEquals;

import org.junit.Test;

/**
 * Tests if all expected artifacts have been generated and the generated
 * constructors behave as expected.
 */
public class ConstructorTest {

	@Test
	public void test() {
		ConstructorExampleGen gen1 = new ConstructorExampleGen();
		assertEquals(5, gen1.field1);

		ConstructorExampleGen gen2 = new ConstructorExampleGen("foobar");
		assertEquals("foobar", gen2.field2);

		ConstructorExampleGen gen3 = new ConstructorExampleGen(10, "abcdef", "foo");
		assertEquals(10, gen3.field1);
		assertEquals("abcdef", gen3.field2);
		assertEquals("foo", gen3.field3);

		ConstructorExampleGen gen4 = new ConstructorExampleGen(0, 11, "abcdefg", " foo ");
		assertEquals(11, gen4.field1);
		assertEquals("abcdefg", gen4.field2);
		assertEquals("foo", gen4.field3);

	}

	@Test(expected = NullPointerException.class)
	public void testNullCheck() {
		new ConstructorExampleGen(0, 11, "abcdefg", null);
	}

}
