package de.japkit.metaannotations;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.classselectors.None;

/**
 * Annotation to add a method to a generated class.
 * 
 * @author stefan
 */
@Documented
@Target(ElementType.METHOD)
public @interface Method {
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Method annotation, it must use this prefix.
	 * 
	 * @return
	 */
	String _prefix() default "<method>";

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
	 * EL Variables within the scope of the method.
	 * 
	 * @return
	 */
	Var[] vars() default {};

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
	 * @return the name of the method. If not empty, nameExpr is ignored.
	 */
	String name() default "";

	/**
	 * For more complex cases: a Java EL expression to generate the name of the
	 * method.
	 * 
	 * @return
	 */
	String nameExpr() default "";

	/**
	 * @return the language of the name expression. Defaults to Java EL.
	 */
	String nameLang() default "";

	/**
	 * @return the return type of the method.
	 */
	Class<?> returnType() default None.class;

	Class<?>[] returnTypeArgs() default {};

	/**
	 * @return the modifiers of the method
	 */
	Modifier[] modifiers() default {};

	/**
	 * A condition whether to add or remove the abstract modifier.
	 * 
	 * @return the boolean expression
	 */
	String abstractCond() default "";

	/**
	 * The expression language for the abstractCond expression.
	 * 
	 * @return the expression language
	 */
	String abstractCondLang() default "";

	/**
	 * As an alternative to the abstractCond expression, a boolean function can
	 * be called.
	 * 
	 * @return the function
	 */
	Class<?>[] abstractCondFun() default {};

	/**
	 * A condition whether to add or remove the public modifier.
	 * 
	 * @return the boolean expression
	 */
	String publicCond() default "";

	/**
	 * The expression language for the publicCond expression.
	 * 
	 * @return the expression language
	 */
	String publicCondLang() default "";

	/**
	 * As an alternative to the publicCond expression, a boolean function can be
	 * called.
	 * 
	 * @return the function
	 */
	Class<?>[] publicCondFun() default {};

	/**
	 * A condition whether to add or remove the private modifier.
	 * 
	 * @return the boolean expression
	 */
	String privateCond() default "";

	/**
	 * The expression language for the privateCond expression.
	 * 
	 * @return the expression language
	 */
	String privateCondLang() default "";

	/**
	 * As an alternative to the privateCond expression, a boolean function can
	 * be called.
	 * 
	 * @return the function
	 */
	Class<?>[] privateCondFun() default {};

	/**
	 * A condition whether to add or remove the protected modifier.
	 * 
	 * @return the boolean expression
	 */
	String protectedCond() default "";

	/**
	 * The expression language for the protectedCond expression.
	 * 
	 * @return the expression language
	 */
	String protectedCondLang() default "";

	/**
	 * As an alternative to the protectedCond expression, a boolean function can
	 * be called.
	 * 
	 * @return the function
	 */
	Class<?>[] protectedCondFun() default {};

	/**
	 * How to map annotations of the source element (???) to the method
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	Annotation[] annotations() default {};

	/**
	 * @return the parameters of the method
	 */
	Param[] parameters() default {};

	/**
	 * Classes to imported for the method body. Allows to use short class names
	 * in the body expr. The imports are only added if they don't conflict with
	 * others. Otherwise, it's an error. TODO: Instead of an error , we could
	 * replace the short name in the body by the fqn.
	 * 
	 * @return
	 */
	Class<?>[] imports() default {};

	/**
	 * If the body shall contain some repetitive code, this expression can be
	 * used. It determines how often to repeat bodyExpr. The iteration variable
	 * is provided as "src" on the value stack (and thus hides the source object
	 * given by the src annotation value).
	 * <p>
	 * A typical example is to iterate over the properties of the class, to
	 * generate methods like toString or equals / hashcode.
	 * 
	 * @return
	 */
	String bodyIterator() default "";

	/**
	 * As an alternative to the bodyIterator expression, a function can be
	 * called.
	 * 
	 * @return
	 */
	Class<?>[] bodyIteratorFun() default {};

	/**
	 * @return the language of the body iterator expression. Default is Java EL.
	 */
	String bodyIteratorLang() default "";

	/**
	 * @return an expression to generate the body. The root property "src"
	 *         refers to the generated method or, if a bodyIterator is used, the
	 *         current iterator element.
	 */
	String bodyCode() default "";

	/**
	 * If there is at least one of the given cases, where all matcher match, the
	 * according expression is use instead of bodyExpr. If no case matches, the
	 * default is bodyExpr.
	 * 
	 * @return
	 */
	Case[] bodyCases() default {};

	/**
	 * @return if bodyIterator is set, this code is inserted between each
	 *         iteration of bodyExpr.
	 */
	String bodySeparator() default "";

	/**
	 * If true, a linebreak is inserted after the "before expression", the "body
	 * expression" and the "after expression".
	 * 
	 * @return
	 */
	boolean bodyLinebreak() default true;

	boolean bodyIndentAfterLinebreak() default false;

	/**
	 * @return an expression for the code to be generated before the repetitive
	 *         bodyCode. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String bodyBeforeIteratorCode() default "";

	/**
	 * @return an expression for the code to be generated after the repetitive
	 *         bodyCode. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String bodyAfterIteratorCode() default "";

	/**
	 * @return an expression for the code to be generated if the iterator
	 *         expression is set but does result in an empty iterator.
	 */
	String bodyEmptyIteratorCode() default "";

	/**
	 * @return the language of the body expression(s). Default is Java EL.
	 */
	String bodyLang() default "";

	/**
	 * @return names of the fragments to surround the generated code body. The
	 *         code to be surrounded is provides as EL variable 'surrounded' to
	 *         the fragment.
	 */
	String[] bodySurroundingFragments() default {};

	/**
	 * @return names of the fragments to be inserted before the generated code
	 *         body.
	 */
	String[] bodyBeforeFragments() default {};

	/**
	 * @return names of the fragments to be inserted after the generated code
	 *         body.
	 */
	String[] bodyAfterFragments() default {};

	/**
	 * @return true means to copy the JavaDoc comment from the rule source
	 *         element
	 */
	boolean commentFromSrc() default false;

	/**
	 * @return an expression to create the JavaDoc comment
	 */
	String commentExpr() default "";

	/**
	 * @return the expression language for commentExpr
	 */
	String commentLang() default "";

	/**
	 * If the method is an annotation value declaration, this is the default
	 * value.
	 * 
	 * @return
	 */
	AV[] defaultAnnotationValue() default {};

	/**
	 * If dependent members are created, the generated method by default becomes
	 * the src element for the according rules. If the original src shall be
	 * used instead, set this AV to false.
	 * 
	 * @return
	 */
	boolean genElementIsSrcForDependentRules() default true;

	/**
	 * The delegate methods to create. The delegate is the return value of the
	 * generated method.
	 * 
	 * @return
	 */
	DelegateMethods[] delegateMethods() default {};

}
