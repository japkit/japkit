package de.stefanocke.japkit.metaannotations;

/**
 * Marks a class a a template. A template can contribute interfaces and members
 * to a generated class.
 * 
 * @author stefan
 * 
 */
@MemberGeneratorAnnotation
public @interface Template {
	/**
	 * An expression to determine the source object for generating this element.
	 * The source element is available as "src" in expressions and is used in
	 * matchers and other rules. If the src expression is not set, the src
	 * element of the parent element is used (usually the enclosing element).
	 * <p>
	 * If this expression results in an Iterable, each object provided by the
	 * Iterator is use as source object. That is, the element is generated
	 * multiple times, once for each object given by the iterator.
	 * 
	 * @return
	 */
	String src() default "";

	/**
	 * 
	 * @return the language of the src expression. Defaults to Java EL.
	 */
	String srcLang() default "";

	/**
	 * By default, the current source object has the name "src" on the value
	 * stack. If this annotation value is set, the source object will
	 * additionally provided under the given name.
	 * 
	 * @return the name of the source variable
	 */
	String srcVar() default "";

	Var[] vars() default {};

	/**
	 * 
	 * @return the annotation mappings
	 */
	Annotation[] annotations() default {};

	/**
	 * If a Field annotation is set here, it defines default values for all
	 * Field annotations within the template.
	 * <p>
	 * For example, one can define a commom name rule for all fields in the
	 * template that appends the src simpleName to the template field's name.
	 * Note that you can access the regarding template method as variable
	 * "template" on the value stack
	 * 
	 * @return
	 */
	Field[] fieldDefaults() default {};

	/**
	 * By default, all fields in the template class are considered to be
	 * templates for fields to be generated, even if they have no @Field
	 * annotation. When setting this to false, you have to put @Field at each
	 * field that shall be a template. Other fields are ignored.
	 * 
	 * @return
	 */
	boolean allFieldsAreTemplates() default true;

	/**
	 * If a Method annotation is set here, it defines default values for all
	 * Method annotations within the template.
	 * <p>
	 * For example, one can define a common name rule for all methods in the
	 * template that appends the src simpleName to the template field's name.
	 * Note that you can access the regarding template method as variable
	 * "template" on the value stack
	 * 
	 * @return
	 */
	Method[] methodDefaults() default {};

	/**
	 * By default, all methods in the template class are considered to be
	 * templates for methods to be generated, even if they have no @Method
	 * annotation. When setting this to false, you have to put @Method at each
	 * method that shall be a template. Other methods are ignored.
	 * 
	 * @return
	 */
	boolean allMethodsAreTemplates() default true;

	/**
	 * If a Constructor annotation is set here, it defines default values for
	 * all Constructor annotations within the template.
	 * <p>
	 * For example, one can define a common expression language to be used for
	 * all constructors in the template. Note that you can access the regarding
	 * template constructor as variable "template" on the value stack
	 * 
	 * @return
	 */
	Constructor[] constructorDefaults() default {};

	/**
	 * When true, all methods in the template class are considered to be
	 * templates for constructors to be generated, even if they have no @Constructor
	 * annotation. When setting this to false, you have to put @Constructor at
	 * each constructor that shall be a template. Other constructors are
	 * ignored.
	 * <p>
	 * If a default constructor shall be generated, it is always required to
	 * annotate the template with @Constructor. (Otherwise, the implicit
	 * constructors of the template classes would always generate default
	 * constructors.)
	 * 
	 * @return
	 */
	boolean allConstructorsAreTemplates() default true;

	/**
	 * 
	 * @return the fields to be generated additional to the ones in the
	 *         template. This can be used for cases where there is little
	 *         "static" code to be generated and a field template would provide
	 *         little benefit.
	 */
	Field[] fields() default {};

	/**
	 * 
	 * @return the methods to be generated for this class. This can be used for
	 *         cases where there is little "static" code to be generated and a
	 *         method template would provide little benefit.
	 */
	Method[] methods() default {};

	/**
	 * 
	 * @return the methods to be generated for this class. This can be used for
	 *         cases where there is little "static" code to be generated and a
	 *         constructor template would provide little benefit.
	 */
	Constructor[] constructors() default {};

	/**
	 * 
	 * @return the inner classes to be generated for this class. 	/**
	 * 
	 * @return the methods to be generated for this class. This can be used for
	 *         cases where there is little "static" code to be generated and a
	 *         template inner class would provide little benefit.
	 */
	InnerClass[] innerClasses() default {};
	
	/**
	 * 
	 * @return the templates to be called by this template.
	 */
	TemplateCall[] templates() default {};
}
