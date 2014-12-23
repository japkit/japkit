package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Annotation;

public @interface Var {
	String name();
	
	/**
	 * If true, the variable is not set if it already exists and is not null or empty.
	 * @return
	 */
	boolean ifEmpty() default false;

	/**
	 * The expression to be evaluated.
	 * 
	 * @return
	 */
	String expr() default "";

	/**
	 * The language for the expression.
	 * @return
	 */
	String lang() default "";

	Class<?> type() default Object.class;

	/**
	 * If set, the according annotation of the result of the expression,
	 * property filter or type query is retrieved. This is possible for
	 * Elements, Collection of Elements, Types and collections of types.
	 * 
	 * @return
	 */
	Class<? extends Annotation>[] annotation() default {};

	
	@interface List {
		Var[] value();
	}
}
