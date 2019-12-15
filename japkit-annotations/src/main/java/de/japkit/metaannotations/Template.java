package de.japkit.metaannotations;

import java.lang.annotation.Documented;

/**
 * Marks a class a a template. A template can contribute interfaces and members
 * to a generated class that are generated from the same src element(s).
 * 
 * @author stefan
 */
@Documented
@MemberGeneratorAnnotation
public @interface Template {
	/**
	 * By default, this rule is active. To switch it on or of case by case, a
	 * boolean expression can be used here.
	 * 
	 * @return
	 */
	String cond() default "";

	/**
	 * The expression language for the cond expression.
	 * 
	 * @return
	 */
	String condLang() default "";

	/**
	 * As an alternative to the cond expression, a boolean function can be
	 * called.
	 * 
	 * @return
	 */
	Class<?>[] condFun() default {};

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
	 * As an alternative to the src expression, a function can be called to
	 * determine the source object.
	 * 
	 * @return
	 */
	Class<?>[] srcFun() default {};

	/**
	 * A filter expression to be applied to src in case it is a collection. Must
	 * be boolean. The variable name for the current collection element to be
	 * filtered is "src".
	 * 
	 * @return
	 */
	String srcFilter() default "";

	/**
	 * As an alternative to srcFilter, one or more boolean functions can be
	 * called. Only if the conjunction of their results is true, the rule is
	 * applied for the considered element of the src collection.
	 * 
	 * @return
	 */
	Class<?>[] srcFilterFun() default {};

	/**
	 * An expression to be applied to the result of the expression or
	 * function(s) in case it is a collection. It's applied to each element. The
	 * variable name for the current collection element is "src". Collect is
	 * applied after filtering.
	 * 
	 * @return
	 */
	String srcCollect() default "";

	/**
	 * As an alternative or additionally to the collect expression, one or more
	 * functions can be called. In case of more than one function, they are
	 * called in a "fluent" style. That is each one is applied to the result of
	 * the previous one. The first function is always applied to the result of
	 * the collect expression or to the current collection element if collect
	 * expression is empty.
	 * 
	 * @return
	 */
	Class<?>[] srcCollectFun() default {};

	/**
	 * If true, and src is a collection, it is transformed to a LinkedHashSet to
	 * remove duplicates while preserving order.
	 * 
	 * @return
	 */
	boolean srcToSet() default false;

	/**
	 * If src is a collection, and srcGroupBy and / or srcGroupByFun are set,
	 * the collection elements are grouped as a map, where the keys are the
	 * results of applying srcGroupBy and / or srcGroupByFun to the collection
	 * elements and the values are lists of collection elements with same key.
	 * SrcGroupBy is an expression and srcGroupByFun is a list of functions.
	 * They are applied in a fluent style (like
	 * src.srcGroupBy().srcGroupByFun[0]().srcGroupByFun[1]()...).
	 * 
	 * @return the expression to derive the key from a collection element. The
	 *         collection element is provided as "src".
	 */
	String srcGroupBy() default "";

	/**
	 * If src is a collection, and srcGroupBy and / or srcGroupByFun are set,
	 * the collection elements are grouped as a map, where the keys are the
	 * results of applying srcGroupBy and / or srcGroupByFun to the collection
	 * elements and the values are lists of collection elements with same key.
	 * SrcGroupBy is an expression and srcGroupByFun is a list of functions.
	 * They are applied in a fluent style (like
	 * src.srcGroupBy().srcGroupByFun[0]().srcGroupByFun[1]()...).
	 * 
	 * @return function(s) to derive the key from a collection element. The
	 *         collection element is provided as "src".
	 */
	Class<?>[] srcGroupByFun() default {};

	/**
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

	/**
	 * Libraries with functions to be made available for use in expressions.
	 */
	Class<?>[] libraries() default {};

	Var[] vars() default {};

	/**
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
	 * templates for constructors to be generated, even if they have
	 * no @Constructor annotation. When setting this to false, you have to
	 * put @Constructor at each constructor that shall be a template. Other
	 * constructors are ignored.
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
	 * @return the fields to be generated additional to the ones in the
	 *         template. This can be used for cases where there is little
	 *         "static" code to be generated and a field template would provide
	 *         little benefit.
	 */
	Field[] fields() default {};

	/**
	 * @return the methods to be generated for this class. This can be used for
	 *         cases where there is little "static" code to be generated and a
	 *         method template would provide little benefit.
	 */
	Method[] methods() default {};

	/**
	 * @return the methods to be generated for this class. This can be used for
	 *         cases where there is little "static" code to be generated and a
	 *         constructor template would provide little benefit.
	 */
	Constructor[] constructors() default {};

	/**
	 * @return the inner classes to be generated for this class. /**
	 * @return the methods to be generated for this class. This can be used for
	 *         cases where there is little "static" code to be generated and a
	 *         template inner class would provide little benefit.
	 */
	InnerClass[] innerClasses() default {};

	/**
	 * @return the templates to be called by this template.
	 */
	TemplateCall[] templates() default {};

	/**
	 * Annotations that shall be accessed by their simple names like this:
	 * typeElement.Entity
	 * 
	 * @return
	 */
	Class<? extends java.lang.annotation.Annotation>[] annotationImports() default {};

	/**
	 * Imported classes to be used in expression language. Those classes must be
	 * available on anntoation processor path.
	 * 
	 * @return
	 */
	Class<?>[] elImportedClasses() default {};

	/**
	 * As an alternative to langImportedClasses, the FQNs of the classes to be
	 * imported can be used here.
	 * 
	 * @return
	 */
	String[] elImportedClassNames() default {};
}
