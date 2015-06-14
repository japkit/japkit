package de.stefanocke.japkit.metaannotations;

import javax.lang.model.element.Modifier;

/**
 * Creates delegate methods. The current "element" on the value stack must be a property or a method.
 * The generated code gets the property or calls the method and uses the result as the delegate
 * 
 * @author stefan
 * 
 */
public @interface DelegateMethods {
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Method annotation, it must use this prefix.
	 * 
	 * @return
	 */
	String _prefix() default "<delegateMethod>";

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
	 * Only the methods of the delegate that are matched by this matcher are used for delegation.
	 * @return
	 */
	Matcher[] methodFilter() default {};


	/**
	 * By default the delegating method has the same name as the delegate method. 
	 * Alternatively, an expression can be used to choose a different name.
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
	 * @return the modifiers of the delegating methods.
	 */
	Modifier[] modifiers() default {};

	/**
	 * How to map annotations of the delegate method to the delegate methods.
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	Annotation[] annotations() default {};

	

	@interface List {
		DelegateMethods[] value();
	}
}
