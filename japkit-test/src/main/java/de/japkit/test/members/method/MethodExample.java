package de.japkit.test.members.method;

import java.util.List;
import java.util.Map;

import javax.validation.constraints.NotNull;

/**
 * The annotated class for the example.
 */
@MethodTrigger
public class MethodExample {
	@NotNull
	String someString;

	int someInt;

	List<String> someStringList;

	Map<String, String> someStringMap;
}
