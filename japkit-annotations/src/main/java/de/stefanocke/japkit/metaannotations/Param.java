package de.stefanocke.japkit.metaannotations;

public @interface Param {
	//TODO: Do we really want to allow overriding for such an "inner" annotation as @Param ?
	String _prefix() default "<methodParam>";
	
	/**
	 * How to map annotations of the source element (???) to the method parameter
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	AnnotationMapping[] annotationMappings() default {};
	
	/** name of the parameter*/
	String name() default "";
	
	/**
	 * For more complex cases: a Java EL expression to generate the name of the
	 * parameter. 
	 * 
	 * @return
	 */
	String nameExpr() default "";

	/**
	 * 
	 * @return the language of the name expression. Defaults to Java EL.
	 */
	String nameLang() default "";
	
	
	Class<?> type();
	
	Class<?>[] typeArgs() default {};
		
}
