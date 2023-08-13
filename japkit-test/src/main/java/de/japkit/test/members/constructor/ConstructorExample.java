package de.japkit.test.members.constructor;

import jakarta.validation.constraints.NotNull;

/**
 * The annotated class for the example.
 */
@ConstructorTrigger
public class ConstructorExample {
	int field1;

	String field2;

	@NotNull
	String field3;
}
