package de.stefanocke.japkit.metaannotations;

/**
 * Can be used in templates to put the generated element(s) of a rule on the
 * value stack. If the src of the rule is an iterable, the value of the result
 * var will be a list.
 */
public @interface ResultVar {
	/** The name of the variable. */
	String value() default "";
}
