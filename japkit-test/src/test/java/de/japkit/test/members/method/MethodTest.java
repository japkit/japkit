package de.japkit.test.members.method;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

import org.junit.Test;

/**
 * Tests if all expected artifacts have been generated and the generated methods
 * behave as expected.
 */
public class MethodTest {

	@Test
	public void test() {
		MethodExampleGen gen1 = new MethodExampleGen();
		gen1.setSomeString("foo");
		gen1.setSomeInt(1);

		MethodExampleGen gen2 = new MethodExampleGen();
		gen2.setSomeString("foo");
		gen2.setSomeInt(1);

		MethodExampleGen gen3 = new MethodExampleGen();
		gen3.setSomeString("foo");
		gen3.setSomeInt(2);

		assertEquals(gen1.hashCode(), gen2.hashCode());
		assertEquals(gen1, gen2);

		assertFalse(gen1.hashCode() == gen3.hashCode());
		assertFalse(gen1.equals(gen3));
		assertFalse(gen1.equals(null));
		assertFalse(gen1.equals(new Object()));
		assertFalse(new Object().equals(gen1));
	}

}
