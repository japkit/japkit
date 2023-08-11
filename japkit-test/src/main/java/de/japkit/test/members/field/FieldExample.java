package de.japkit.test.members.field;

import java.util.List;

import jakarta.validation.constraints.NotNull;

/**
 * The annotated class for the example.
 */
@FieldTrigger
public class FieldExample {
	@NotNull
	String someString;
	int someInt;
	List<String> someStringList;
}
