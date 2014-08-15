package de.stefanocke.japkit.metaannotations;

/**Annotation value.*/
public @interface AV {
	
	/**
	 * By default, this annotation mapping is active an will copy or map the AV.
	 * To switch it on or of case by case, a Matcher can be used here. 
	 * <p>
	 * In case of multiple matchers, at least one must match to activate the
	 * rule.
	 * 
	 * @return the matcher
	 */
	Matcher[] activation() default {};
	
	
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
