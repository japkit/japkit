package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * Annotation to add a method to a generated class.
 * 
 * @author stefan
 * 
 */
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
	 * EL Variables within the scope of the method.
	 * 
	 * @return
	 */
	Var[] vars() default {};

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
	 * 
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
	 * 
	 * @return the language of the name expression. Defaults to Java EL.
	 */
	String nameLang() default "";

	/**
	 * 
	 * @return the return type of the method.
	 */
	Class<?> returnType() default None.class;

	Class<?>[] returnTypeArgs() default {};

	/**
	 * 
	 * @return the modifiers of the method
	 */
	Modifier[] modifiers() default {};

	/**
	 * How to map annotations of the source element (???) to the method
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	Annotation[] annotations() default {};

	/**
	 * 
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
	 * 
	 * @return
	 */
	String bodyIterator() default "";

	/**
	 * 
	 * @return the language of the body iterator expression. Default is Java EL.
	 */
	String bodyIteratorLang() default "";

	/**
	 * 
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
	 * 
	 * @return if bodyIterator is set, this code is inserted between each
	 *         iteration of bodyExpr.
	 */
	String bodySeparator() default "";
	
	/**
	 * If true, a linebreak is inserted after the "before expression", the "body expression" and the "after expression".
	 * @return
	 */
	boolean bodyLinebreak() default true;
	
	boolean bodyIndentAfterLinebreak() default false;

	/**
	 * 
	 * @return an expression for the code to be generated before the repetitive
	 *         bodyCode. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String bodyBeforeIteratorCode() default "";

	/**
	 * 
	 * @return an expression for the code to be generated after the repetitive
	 *         bodyCode. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String bodyAfterIteratorCode() default "";

	/**
	 * 
	 * @return an expression for the code to be generated if the iterator
	 *         expression is set but does result in an empty iterator.
	 */
	String bodyEmptyIteratorCode() default "";

	/**
	 * 
	 * @return the language of the body expression(s). Default is Java EL.
	 */
	String bodyLang() default "";

	/**
	 * 
	 * @return names of the fragments to surround the generated code body.
	 */
	String[] surroundingFragments() default {};

	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code
	 *         body.
	 */
	String[] beforeFragments() default {};

	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code
	 *         body.
	 */
	String[] afterFragments() default {};

	/**
	 * 
	 * @return true means to copy the JavaDoc comment from the rule source
	 *         element
	 */
	boolean commentFromSrc() default false;

	/**
	 * 
	 * @return an expression to create the JavaDoc comment
	 */
	String commentExpr() default "";

	/**
	 * 
	 * @return the expression language for commentExpr
	 */
	String commentLang() default "";
	
	
	/**
	 * If the method is an annotation value declaration, this is the default value. 
	 * @return
	 */
	AV[] defaultAnnotationValue() default {}; 

	/**
	 * If dependent members are created, the generated method by default becomes the src element for the according rules.
	 * If the original src shall be used instead, set this AV to false. 
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
