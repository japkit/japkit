package de.japkit.metaannotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.classselectors.BehaviorInnerClassWithGenClassPrefix;
import de.japkit.metaannotations.classselectors.None;

/**
 * Meta annotation. When put on an annotation, this annotation will generate a
 * new Java class.
 * 
 * @author stefan
 * 
 */
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
	 * If true, and src is a collection, it is transformed to a LinkedHashSet to remove duplicates while preserving order.
	 * 
	 * @return
	 */
	boolean srcToSet() default false;
	
	/**
	 * If src is a collection, and srcGroupBy and / or srcGroupByFun are set, the collection elements are grouped as a map, where 
	 * the keys are the results of applying srcGroupBy and / or srcGroupByFun to the collection elements and the values are lists 
	 * of collection elements with same key. SrcGroupBy is an expression and srcGroupByFun is a list of functions. 
	 * They are applied in a fluent style (like src.srcGroupBy().srcGroupByFun[0]().srcGroupByFun[1]()...).
	 * 
	 * @return the expression to derive the key from a collection element. The collection element is provided as "src".
	 */
	String srcGroupBy() default "";
	
	/**
	 * If src is a collection, and srcGroupBy and / or srcGroupByFun are set, the collection elements are grouped as a map, where 
	 * the keys are the results of applying srcGroupBy and / or srcGroupByFun to the collection elements and the values are lists 
	 * of collection elements with same key. SrcGroupBy is an expression and srcGroupByFun is a list of functions. 
	 * They are applied in a fluent style (like src.srcGroupBy().srcGroupByFun[0]().srcGroupByFun[1]()...).
	 * 
	 * @return function(s) to derive the key from a collection element. The collection element is provided as "src".
	 */
	Class<?>[] srcGroupByFun() default {};
		
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
	 * @return the kind of type element to generate. Allowed values: CLASS, INTERFACE, ENUM
	 */
	ElementKind kind() default ElementKind.CLASS;
	
	/**
	 * 
	 * @return the superclass for the generated class.
	 */
	Class<?> superclass() default None.class;

	/**
	 * 
	 * @return the type arguments for the superclass
	 */
	Class<?>[] superclassArgs() default {};

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
	Class<?>[] interface1Args() default {};

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
	Class<?>[] interface2Args() default {};
	
	/**
	 * 
	 * @return the modifiers for the generated class
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
	 * As an alternative to the abstractCond expression, a boolean function can be called.
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
	 * As an alternative to the publicCond expression, a boolean function can be called.
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
	 * As an alternative to the privateCond expression, a boolean function can be called.
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
	 * As an alternative to the protectedCond expression, a boolean function can be called.
	 * 
	 * @return the function
	 */
	Class<?>[] protectedCondFun() default {};
	
	/**
	 * By default, the abstract modifier on a class template is always removed  when generating a class. 
	 * The rationale behind this is to allow abstract method templates (to avoid writing dummy method bodies).
	 * This behavior can be switched off by setting this annotation value to false.
	 * 
	 * @return whether to keep the abstract modifier
	 */
	boolean keepAbstract() default false;

	/**
	 * If true, the modifiers from the current src element a copied and merged with the ones given by modifiers AV.
	 * @return
	 */
	boolean modifiersFromSrc() default false;

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
	 * @return the templates to be called to contribute members to the generated class
	 */
	TemplateCall[] templates() default {};

	/**
	 * If true, a custom behavior delegation mechanism is generated. Woohaa...
	 * 
	 * @return
	 */
	Matcher[]  customBehaviorActivation() default {};

	Class<?> behaviorClass() default BehaviorInnerClassWithGenClassPrefix.class;
	
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
	
	/**
	 * Imported classes to be used in expression language. Those classes must be available on anntoation processor path.
	 * 
	 * @return
	 */
	Class<?>[] elImportedClasses() default {};
	
	/**
	 * As an alternative to langImportedClasses, the FQNs of the classes to be imported can be used here.
	 * 
	 * @return
	 */
	String[] elImportedClassNames() default {};

}
