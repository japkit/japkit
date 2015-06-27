package de.japkit.metaannotations;

/**Calls a Java template to contribute members to the generated class.*/
public @interface TemplateCall {
	
	/**
	 * By default, this rule is active.
	 * To switch it on or of case by case, a boolean expression can be used here. 
	 * 
	 * @return 
	 */
	String cond() default "";
	
	/**
	 * The expression language for the cond expression.
	 * @return
	 */
	String condLang() default "";
	
	/**
	 * As an alternative to the cond expression, a boolean function can be called.
	 * 
	 * @return
	 */
	Class<?>[] condFun() default {};
	
	/**
	 * An expression to determine the source object for calling the template.
	 * The source element is available as "src" in expressions and is used in
	 * matchers and other rules. If the src expression is not set, the src
	 * element of the parent is used.
	 * <p>
	 * If this expression results in an Iterable, each object provided by the
	 * Iterator is use as source object. That is, the template is called
	 * multiple times, once for each object given by the iterator.
	 * 
	 * @return
	 */
	String src() default "";

	/**
	 * As an alternative to the src expression, a function can be called to determine the source object.
	 * 
	 * @return
	 */
	Class<?>[] srcFun() default {};

	/**
	 * A filter expression to be applied to src in case it is a collection. Must be boolean. 
	 * The variable name for the current collection element to be filtered is "src". 
	 * @return
	 */
	String srcFilter() default "";

	/**
	 * As an alternative to srcFilter, one or more boolean functions can be called. 
	 * Only if the conjunction of their results is true, the rule is applied for the considered element of the src collection.
	 * 
	 * @return
	 */
	Class<?>[] srcFilterFun() default {};
	
	/**
	 * An expression to be applied to the result of the expression or function(s) in case it is a collection. It's applied to each element.
	 * The variable name for the current collection element is "src". Collect is applied after filtering.
	 * 
	 * @return
	 */
	String srcCollect() default "";

	/**
	 * As an alternative or additionally to the collect expression, one or more functions can be called. 
	 * In case of more than one function, they are called in a "fluent" style. That is each one is applied to the result of the previous one. 
	 * The first function is always applied to the result of the collect expression or to the current collection element if collect expression is empty.
	 *  
	 * @return
	 */
	Class<?>[] srcCollectFun() default {};
	
	/**
	 * 
	 * @return the language of the src expression. Defaults to Java EL.
	 */
	String srcLang() default "";
	
	/**
	 * By default, the current source object has the name "src" on the value stack.
	 * If this annotation value is set, the source object will additionally provided under the given name.  
	 * 
	 * @return the name of the source variable
	 */
	String srcVar() default "";

	/**
	 * EL Variables within the scope of the template call. Can be used as parameters for the template. 
	 * 
	 * @return
	 */
	Var[] vars() default {};
	
	/**
	 * 
	 * @return the template class 
	 */
	Class<?> value();
}
