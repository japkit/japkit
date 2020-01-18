package de.japkit.test.members.common.condition;

import static java.util.Arrays.asList;
import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class ConditionTest {

	public void conditonTrueTest() {
		ConditionExampleTrueGen gen = new ConditionExampleTrueGen();

		asList(gen.someField1, gen.someField2, gen.someMethod(), gen.someFieldInTemplate, gen.someMethodInTemplate(),
				new ConditionExampleTrueGen.SomeInnerClass());
	}

	@Test
	public void conditonFalseTest() {
		Class<?> genClass = new ConditionExampleFalseGen().getClass();
		assertEquals("Shall have no fields.", 0, genClass.getDeclaredFields().length);
		assertEquals("Shall have no methods", 0, genClass.getDeclaredMethods().length);
		assertEquals("Shall have no inner classes", 0, genClass.getDeclaredClasses().length);
	}
}
