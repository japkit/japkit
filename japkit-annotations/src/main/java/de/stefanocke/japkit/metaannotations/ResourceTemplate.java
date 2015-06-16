package de.stefanocke.japkit.metaannotations;

public @interface ResourceTemplate {
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * ResourceTemplate annotation, it must use this prefix.
	 * 
	 * @return
	 */
	String _prefix() default "<resourceTemplate>";

	/**
	 * An expression to determine the source object for this resource template.
	 * The source element is available as "src" in expressions and is used in
	 * matchers and other rules. If the src expression is not set, the src
	 * element is the annotated class.
	 * <p>
	 * If this expression results in an Iterable, each object provided by the
	 * Iterator is use as source object. That is, the element is generated
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
	 * 
	 * @return the template language
	 */
	String templateLang();

	/**
	 * 
	 * @return the template file name. The file must be in same package as the
	 *         trigger annotation.
	 */
	String templateName();

	/**
	 * The expression to determine the name of the resource file to generate.
	 * 
	 * @return
	 */
	String nameExpr() default "";

	/**
	 * 
	 * @return the language of the name expression. Defaults to Java EL.
	 */
	String nameLang() default "";

	/**
	 * The expression to determine the path of the resource file to
	 * generate.
	 * 
	 * @return
	 */
	String pathExpr() default "";

	/**
	 * 
	 * @return the language of the path name expression. Defaults to Java EL.
	 */
	String pathLang() default "";

	/**
	 * The regular expression that the annotated class package must match.
	 * 
	 * @return
	 */
	String pathRegEx() default "";

	/**
	 * 
	 * @return the regular expression replacement to determine the path name
	 *         of the resource file to generate from the package of the
	 *         annotated class.
	 */
	String pathRegExReplace() default "";
	
	/**
	 * 
	 * @return the location where to put the generated resource file.
	 */
	ResourceLocation location() default ResourceLocation.GENERATED_RESOURCES;
	
	/**
	 * EL Variables in the scope of the template. 
	 * @return
	 */
	Var[] vars() default {};

	@interface List {
		ResourceTemplate[] value() default {};
	}
}
