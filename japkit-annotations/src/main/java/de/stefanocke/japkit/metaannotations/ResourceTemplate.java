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
