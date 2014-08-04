package de.stefanocke.japkit.metaannotations;

import javax.lang.model.element.Element;
import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * Anntoation to add a field to a generated class.
 * 
 * @author stefan
 * 
 */
@MemberGeneratorAnnotation
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
	 * EL Variables within the scope of the field. The root property "element"
	 * refers to the enclosing class or to the current element of the iterator.
	 * 
	 * @return
	 */
	Var[] vars() default {};

	/**
	 * By default, this field annotation is active and will generate a field.
	 * To switch it on or of case by case, a Matcher can be used here. The
	 * element on which the matcher is applied is the enclosing class.
	 * <p>
	 * In case of multiple matchers, at least one must match to activate the rule.
	 * 
	 * @return
	 */
	Matcher[] activation() default {};

	/**
	 * 
	 * @return the name of the method. If not empty, nameExpr is ignored.
	 */
	String name() default "";

	/**
	 * For more complex cases: a Java EL expression to generate the name of the
	 * field. The root property "element" refers to the enclosing class.
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
	AnnotationMapping[] annotationMappings() default {};

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
	 *         initExpr. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String initBeforeExpr() default "";

	/**
	 * 
	 * @return an expression for the code to be generated after the repetitive
	 *         initExpr. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String initAfterExpr() default "";

	/**
	 * 
	 * @return an expression for the code to be generated if the iterator
	 *         expression is set but does result in an empty iterator.
	 */
	String initEmptyExpr() default "";

	/**
	 * 
	 * @return a Java EL expression to generate the initializer. The root
	 *         property "element" refers to the generated field.
	 */
	String initExpr() default "";
	
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
	
	@interface List {
		Field[] value();
	}
}
