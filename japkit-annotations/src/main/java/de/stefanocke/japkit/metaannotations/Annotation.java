package de.stefanocke.japkit.metaannotations;


@MemberGeneratorAnnotation
public @interface Annotation {

	/**
	 * An identifier to refer to this annotation mapping within annotation value
	 * mappings. If this value is set, the annotation mapping is only applied
	 * within those annotation value mappings that refer to it, but not as a top
	 * level mapping.
	 * <p>
	 * The reason for this mechanism is that annotations cannot be contain
	 * themselves recursively.
	 * 
	 * @return the id
	 */
	String id() default "";

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
	 * An expression to determine the source object for generating this annotation(s).
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
	 * By default, the current source object has the name "src" on the value stack.
	 * If this annotation value is set, the source object will additionally provided under the given name.  
	 * 
	 * @return the name of the source variable
	 */
	String srcVar() default "";

	/**
	 * EL Variables within the scope of the annotation rule. 
	 * 
	 * @return
	 */
	//TODO: Is cyclic now, but could work if we remove annotation mappings from @Properties
	//Var[] vars() default {};

	/**
	 * 
	 * @return the annotations to copy from source to target element.
	 */
	Class<? extends java.lang.annotation.Annotation>[] copyAnnotations() default {};

	/**
	 * 
	 * @return annotations contained in those packages will be copied from
	 *         source to target element. The package names must either end with
	 *         .* or with .**. In case of .* only the package itself is
	 *         considered. In case of .**, the sub packages are considered as
	 *         well. For including all packages, use *.
	 */
	String[] copyAnnotationsFromPackages() default {};

	/**
	 * When copying annotations that trigger code generation, this will
	 * introduce infinite loops. Thus, when a trigger annotation is copied, an
	 * annotation value named "shadow" will be searched and set to true. The
	 * annotation processor will skip such annotations in the next round. It is
	 * an error if a trigger annotation to be copied does not declare an
	 * annotation value with the name "shadow".
	 * 
	 * @return true means to set the annotation value "shadow" will be set to
	 *         true.
	 */
	boolean setShadowOnTriggerAnnotations() default true;

	/**
	 * 
	 * @return the annotation to be created on the target element.
	 */
	Class<? extends java.lang.annotation.Annotation> targetAnnotation() default DefaultAnnotation.class;

	/**
	 * 
	 * @return mappings for the annotation values
	 */
	AV[] values() default {};

	AnnotationMode mode() default AnnotationMode.ERROR_IF_EXISTS;

	
	@interface List {
		Annotation[] value();
	}
}
