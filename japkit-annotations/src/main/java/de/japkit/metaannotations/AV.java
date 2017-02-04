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
	 * An expression to determine the source object for generating this annotation value(s).
	 * The source element is available as "src" in expressions. If the src expression is not set, the src
	 * element of the parent element is used (usually the enclosing element).
	 * <p>
	 * If this expression results in an Iterable, each object provided by the
	 * Iterator is use as source object. That is, the annotation value is generated
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
	 * 
	 * @return the language of the src expression. Defaults to Java EL.
	 */
	String srcLang() default "";
	
	
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
