package de.stefanocke.japkit.metaannotations;


public @interface Function {

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

	/** The return type of the function */
	Class<?> type() default Object.class;

	
}
