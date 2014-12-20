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
	 * If true, the EL-Variable is not evaluated immediately. Instead, it is
	 * put as a function on the value stack and can be evaluated later by
	 * calling its eval, filter or map method. The parameter to this methods must
	 * be the element or list of elements to apply the function for.
	 * 
	 * @return
	 */
	boolean isFunction() default false;


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
	 * If this value is set, the expression is ignored and the variable is a
	 * list of properties instead, according to the given filter criteria.
	 * 
	 * @return
	 */
	Properties[] propertyFilter() default {};

	/**
	 * If this value is set, the expression is ignored and a type query is executed instead.
	 * 
	 * @return
	 */
	TypeQuery[] typeQuery() default {};

	/**
	 * If set, and expr is set, the matcher is applied to the result of
	 * expression and the result (true or false) is put on value stack. 
	 */
	Matcher[] matcher() default {};

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
