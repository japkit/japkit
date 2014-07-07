package de.stefanocke.japkit.metaannotations;

public @interface Case {
	Matcher[] matcher() default {};
	String expr();
}
