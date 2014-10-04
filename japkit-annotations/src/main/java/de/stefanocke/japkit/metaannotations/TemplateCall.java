package de.stefanocke.japkit.metaannotations;

/**Calls a Java template to contribute members to the generated class.*/
public @interface TemplateCall {
	
	/**
	 * By default, this annotation is active an will call the template.
	 * To switch it on or of case by case, a Matcher can be used here.
	 * <p>
	 * In case of multiple matchers, at least one must match to activate the
	 * rule.
	 * 
	 * @return
	 */
	Matcher[] activation() default {}; 
	
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
	 * A filter expression to be applied to src in case it is a collection. Must be boolean. 
	 * The variable name for the current collection element to be filtered is "src". 
	 * @return
	 */
	String srcFilter() default "";

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
