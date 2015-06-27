package de.japkit.metaannotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.classselectors.None;

/**
 * Anntoation to add a field to a generated class.
 * 
 * @author stefan
 * 
 */
@Target(ElementType.FIELD)
public @interface Field {
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Method annotation, it must use this prefix.
	 * 
	 * @return
	 */
	String _prefix() default "<field>";

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
	 * An expression to be applied to the result of the expression or function(s) in case it is a collection. It's applied to each element.
	 * The variable name for the current collection element is "src". Collect is applied after filtering.
	 * 
	 * @return
	 */
	String srcCollect() default "";

	/**
	 * As an alternative or additionally to the collect expression, one or more functions can be called. 
	 * In case of more than one function, they are called in a "fluent" style. That is each one is applied to the result of the previous one. 
	 * The first function is always applied to the result of the collect expression or to the current collection element if collect expression is empty.
	 *  
	 * @return
	 */
	Class<?>[] srcCollectFun() default {};
	
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
	 * EL Variables within the scope of the field.
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
	 * field.
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
	 * @return the type of the field.
	 */
	Class<?> type() default None.class;

	Class<?>[] typeArgs() default {};

	/**
	 * 
	 * @return the modifiers of the field
	 */
	Modifier[] modifiers() default {};

	/**
	 * How to map annotations of the source element (???) to the field
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	Annotation[] annotations() default {};

	/**
	 * Classes to be imported for the initializer. Allows to use short class
	 * names in the expr. The imports are only added if they don't conflict with
	 * others. Otherwise, it's an error. TODO: Instead of an error , we could
	 * replace the short name in the body by the fqn.
	 * 
	 * @return
	 */
	Class<?>[] imports() default {};

	/**
	 * If the init expression shall contain some repetitive code, this
	 * expression can be used. It determines how often to repeat initExpr. The
	 * iteration variable is provided as "src" on the value stack (and thus
	 * hides the source object given by the src annotation value).
	 * <p>
	 * A typical example is to initialize some array with the names of the
	 * properties of the class.
	 * 
	 * 
	 * @return
	 */
	String initIterator() default "";

	/**
	 * 
	 * @return the language of the init iterator expression. Default is Java EL.
	 */
	String initIteratorLang() default "";

	/**
	 * 
	 * @return if inityIterator is set, this code is inserted between each
	 *         iteration of initExpr.
	 */
	String initSeparator() default "";
	
	/**
	 * If true, a linebreak is inserted after the "before expression", the "init expression" and the "after expression".
	 * @return
	 */
	boolean initLinebreak() default false;

	/**
	 * 
	 * @return an expression for the code to be generated before the repetitive
	 *         initCode. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String initBeforeIteratorCode() default "";

	/**
	 * 
	 * @return an expression for the code to be generated after the repetitive
	 *         initCode. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String initAfterIteratorCode() default "";

	/**
	 * 
	 * @return an expression for the code to be generated if the iterator
	 *         expression is set but does result in an empty iterator.
	 */
	String initEmptyIteratorCode() default "";

	/**
	 * 
	 * @return a Java EL expression to generate the initializer. The root
	 *         property "src" refers to the generated field or to the iterator variable.
	 */
	String initCode() default "";
	
	/**
	 * If there is at least one of the given cases, where all matcher match, the according expression is use instead of initExpr.
	 * If no case matches, the default is initExpr.
	 * 
	 * @return
	 */
	Case[] initCases() default{};

	/**
	 * 
	 * @return the language of the init expression. Default is Java EL.
	 */
	String initLang() default "";

	/**
	 * The delegate methods to create. The delegate is the generated field.
	 * 
	 * @return
	 */
	DelegateMethods[] delegateMethods() default {};
	
	/**
	 * 
	 * @return true means to copy the JavaDoc comment from the rule source element 
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
	 * If dependent members are created, the generated field by default becomes the src element for the according rules.
	 * If the original src shall be used instead, set this AV to false. 
	 * @return
	 */
	boolean genElementIsSrcForDependentRules() default true;
	
	
	/**
	 * A Setter annotation here means to generate a setter for the field. The
	 * annotation can be used to further customize the setter, but all values
	 * are optional.
	 * 
	 * @return the setter annotation
	 */
	Setter[] setter() default {};

	/**
	 * A Getter annotation here means to generate a getter for the field. The
	 * annotation can be used to further customize the getter, but all values
	 * are optional.
	 * 
	 * @return the setter annotation
	 */
	Getter[] getter() default {};
	
	/**
	 * A class to customize the generated fields. So far, you can override the annotations of the field or add new annotations.
	 * <p>
	 * TODO: Remove annotations?  f.e.  @Not({NotNull.class, ...}) 
	 * Enforce Field order? 
	 * Complex annotation mapping modes?
	 * 
	 * @return
	 */
	Class<?> manualOverrides() default None.class;

	/**
	 * By default, all fields of the "overrides" class are considered. This can
	 * be changed by setting another matcher here. For example, only fields with
	 * some specific annotation could be considered. Or, methods could be
	 * considered that are named like the properties.
	 * 
	 * @return
	 */
	Matcher manualOverridesMatcher() default @Matcher(kind = ElementKind.FIELD);
	

}
