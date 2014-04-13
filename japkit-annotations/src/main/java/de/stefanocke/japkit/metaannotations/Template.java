package de.stefanocke.japkit.metaannotations;

/**
 * Marks a class a a template. A template can contribute interfaces and members to a generated class.
 * @author stefan
 *
 */
public @interface Template {
	Var[] vars() default {};
}
