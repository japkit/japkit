package de.stefanocke.japkit.metaannotations;

public @interface AVMapping {
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

	AVMappingMode mode() default AVMappingMode.ERROR_IF_EXISTS;
}
