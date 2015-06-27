package de.japkit.metaannotations;

public @interface Var {
	String name() default "";
	
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
	
	/**
	 * As an alternative or additionally to the expression, a function can be called to calculate the value for the variable.
	 * In case of more than one function, they are called in a "fluent" style. That is each one is applied to the result of the previous one.
	 * The first function is always applied to the result of the expr or to the current "src" if expr is empty. 
	 * 
	 * @return
	 */
	Class<?>[] fun() default {};
	
	/**
	 * A filter expression to be applied to the result of the expression or function(s) in case it is a collection. Must be boolean. 
	 * The variable name for the current collection element to be filtered is "src". 
	 * @return
	 */
	String filter() default "";

	/**
	 * As an alternative to filter, one or more boolean functions can be called. 
	 * Only if the conjunction of their results is true, the rule is applied for the considered element of the src collection.
	 * 
	 * @return
	 */
	Class<?>[] filterFun() default {};
	
	/**
	 * An expression to be applied to the result of the expression or function(s) in case it is a collection. It's applied to each element.
	 * The variable name for the current collection element is "src". Collect is applied after filtering.
	 * 
	 * @return
	 */
	String collect() default "";

	/**
	 * As an alternative or additionally to the collect expression, one or more functions can be called. 
	 * In case of more than one function, they are called in a "fluent" style. That is each one is applied to the result of the previous one. 
	 * The first function is always applied to the result of the collect expression or to the current collection element if collect expression is empty.
	 *  
	 * @return
	 */
	Class<?>[] collectFun() default {};
	

	Class<?> type() default Object.class;
	
	/**
	 * Whether the variable might be null. By default, this is not allowed.
	 * @return
	 */
	boolean nullable() default false;


	
	@interface List {
		Var[] value();
	}
}
