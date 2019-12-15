package de.japkit.metaannotations;

import java.lang.annotation.Documented;

/**
 * An expression or {@link CodeFragment} with multiple alternatives from which
 * one is selected.
 */
@Documented
public @interface Switch {
	/**
	 * An expression to determine the source object for this switch rule.
	 * 
	 * @return
	 */
	String src() default "";

	/**
	 * As an alternative to the src expression, a function can be called to
	 * determine the source object.
	 * 
	 * @return
	 */
	Class<?>[] srcFun() default {};

	/**
	 * @return the language of the src expression. Defaults to Java EL.
	 */
	String srcLang() default "";

	/**
	 * EL Variables within the scope of the switch.
	 * 
	 * @return
	 */
	Var[] vars() default {};

	Case[] value() default {};
}
