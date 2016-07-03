package de.japkit.metaannotations;

/**Annotation value.*/
public @interface AV {
	
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
	 * 
	 * @return the name of the target annotation value
	 */
	String name();

	/**
	 * 
	 * @return the annotation value as a string
	 */
	String value() default "";

	/**
	 * 
	 * @return the annotation value as expression
	 */
	String expr() default "";
	
	/**
	 * 
	 * @return the expression language. Defaults to Java EL.
	 */
	String lang() default "";

	/**
	 * To create annotations as annotation values, an annotation mapping can be
	 * referenced here by its Id. If expr is also set, the expression is
	 * expected to yield an element or a collection of elements for which to
	 * apply the annotation mapping.
	 * 
	 * @return the id of the annotation mapping.
	 */
	String annotationMappingId() default "";

	AVMode mode() default AVMode.ERROR_IF_EXISTS;
}
