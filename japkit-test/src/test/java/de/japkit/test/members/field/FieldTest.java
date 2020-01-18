package de.japkit.test.members.field;

import static java.util.Arrays.asList;
import static junit.framework.Assert.assertEquals;
import static org.junit.Assert.assertArrayEquals;

import java.util.ArrayList;
import java.util.List;

import org.junit.Test;

/**
 * Tests if all expected artifacts have been generated and the generated methods
 * behave as expected.
 */
public class FieldTest {

	@Test
	public void test() {
		FieldExampleGen gen = new FieldExampleGen();

		assertEquals("foobar", gen.getFixedField());

		gen.setFixedField("barfoo");
		assertEquals("barfoo", gen.getFixedField());

		List<String> someStringList = new ArrayList<>(asList("3", "4"));

		gen.someInt(1).someString("2").someStringList(someStringList);

		assertEquals(1, gen.getSomeInt());
		assertEquals("2", gen.getSomeString());
		assertEquals(asList("3", "4"), gen.getSomeStringList());

		// Mutate original list to test defensive copy works
		someStringList.add("5");
		assertEquals(asList("3", "4"), gen.getSomeStringList());

		// This test may fail during Eclipse incremental build.
		// This is related to
		// https://bugs.eclipse.org/bugs/show_bug.cgi?id=500589
		assertArrayEquals(new String[] { "someString", "someInt", "someStringList" }, FieldExampleGen.FIELD_NAMES);
	}

	@Test(expected = IllegalArgumentException.class)
	public void testNullCheck() {
		FieldExampleGen gen = new FieldExampleGen();
		gen.someString(null);
	}

}
