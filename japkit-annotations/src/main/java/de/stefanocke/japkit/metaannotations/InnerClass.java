package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * Meta annotation. When put on an annotation, this annotation will generate a
 * new Java class.
 * 
 * @author stefan
 * 
 */
@MemberGeneratorAnnotation
@Target(ElementType.TYPE)
public @interface InnerClass {
	
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Method annotation, it must use this prefix.
	 * 
	 * @return
	 */
	String _prefix() default "<innerClass>";
	
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
	 * By default, this annotation is active and will generate an inner class.
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
	 * @return the kind of type element to generate. Allowed values: CLASS, INTERFACE, ENUM
	 */
	ElementKind kind() default ElementKind.CLASS;
	
	/**
	 * 
	 * @return the superclass for the generated class. By default it is Object.
	 */
	Class<?> superclass() default Object.class;

	/**
	 * 
	 * @return the type arguments for the superclass
	 */
	Class<?>[] superclassTypeArgs() default {};

	/**
	 * 
	 * @return the interface implemented by the generated class. By default, no
	 *         interface is implemented.
	 */
	Class<?> interface1() default None.class;

	/**
	 * 
	 * @return the type arguments for the interface
	 */
	Class<?>[] interface1TypeArgs() default {};

	/**
	 * 
	 * @return a second interface implemented by the generated class. By
	 *         default, no interface is implemented.
	 */
	Class<?> interface2() default None.class;

	/**
	 * 
	 * @return the type arguments for the second interface
	 */
	Class<?>[] interface2TypeArgs() default {};
	
	/**
	 * 
	 * @return the modifiers for the generated class
	 */
	Modifier[] modifier() default {};


	/**
	 * The expression for the class name. 
	 */
	String nameExpr() default "";

	String nameLang() default "";


	/**
	 * How to map annotations of the annotated class to the target class.
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	Annotation[] annotations() default {};
	
	/**
	 * 
	 * @return the members to be generated for this class. 
	 */
	Members[] members() default {};

	/**
	 * If true, a custom behavior delegation mechanism is generated. Woohaa...
	 * 
	 * @return
	 */
	boolean customBehavior() default false;

	Class<?> behaviorClass() default InnerClassBehaviorInnerClass.class;
	
	/**
	 * The behavior class for an inner class is an inner class of the annotated class whose name is #{simpleNameOfInnerClass}Behavior
	 * @author stefan
	 *
	 */
	@ClassSelector(kind=ClassSelectorKind.INNER_CLASS_NAME, expr="#{currentGenClass.simpleName}Behavior")
	public interface InnerClassBehaviorInnerClass{}



	/**
	 * 
	 * @return the name of the base class for the behavior class. It is always
	 *         an inner class of the generated class.
	 */
	String behaviorAbstractClass() default "AbstractBehavior";

	/**
	 * The interface that is provided to the behavior class to access all
	 * methods (espec. including private ones) of the generated class.
	 * 
	 * @return the name of the interface. If it is not an inner class of the
	 *         generated class, than this value is the suffix to append to the
	 *         name of the generated class to get the name of the interface.
	 */
	String behaviorInternalInterface() default "Internal";

	/**
	 * @return true means, the internacl interface is generated as inner class
	 *         of generated class. false means, it is generated as top level
	 *         class. Note: Compilation errors may appear in eclipse, when that is set to true.
	 */
	boolean behaviorInternalInterfaceIsInnerClass() default false;
	
	/**
	 * 
	 * @return the name of the implementation class for the internal interface. This is always an inner class of the generated class.
	 */
	String behaviorInternalInterfaceImpl() default "InternalImpl";
	
	/**
	 * If the user declares a method in the behavior class that already exists in the generated class, than the generated method is renamed.
	 * This allows the used declared method to call the generated method and so kind of "wrapping" it.
	 * <p>
	 * This idea was taken from Eclipse Modeling Framework.
	 * 
	 * @return the prefix to use when renaming a generated method.
	 */
	String behaviorGenMethodRenamePrefix() default "gen";
	
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
	 * EL Variables in the scope of the generated class. 
	 * @return
	 */
	Var[] vars() default {};
	
	/**
	 * 
	 * @return the fields to be generated for this class.
	 */
	Field[] fields() default {};
	
	/**
	 * 
	 * @return the methods to be generated for this class.
	 */
	Method[] methods() default {};
	
	/**
	 * 
	 * @return the constructors to be generated for this class.
	 */
	Constructor[] constructors() default {};
	
	

}
