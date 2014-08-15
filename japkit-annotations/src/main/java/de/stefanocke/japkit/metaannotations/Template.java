package de.stefanocke.japkit.metaannotations;

/**
 * Marks a class a a template. A template can contribute interfaces and members to a generated class.
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
	 * By default, the current source object has the name "src" on the value stack.
	 * If this annotation value is set, the source object will additionally provided under the given name.  
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
	 * If a Field annotation is set here, it defines default values for all Field annotations within the template.
	 * <p>
	 * For example, one can define a commom name rule for all fields in the template that appends the src simpleName to the template field's name.
	 * Note that you can access the regarding template method as variable "template" on the value stack
	 * @return
	 */
	Field[] fieldDefaults() default {}; 
	
	/**
	 * If a Method annotation is set here, it defines default values for all Method annotations within the template.
	 * <p>
	 * For example, one can define a common name rule for all methods in the template that appends the src simpleName to the template field's name.
	 * Note that you can access the regarding template method as variable "template" on the value stack
	 * @return
	 */
	Method[] methodDefaults() default {}; 
	
	/**
	 * If a Constructor annotation is set here, it defines default values for all Constructor annotations within the template.
	 * <p>
	 * For example, one can define a common expression language to be used for all constructors in the template.
	 * Note that you can access the regarding template constructor as variable "template" on the value stack
	 * @return
	 */
	Constructor[] constructorDefaults() default {}; 
}
