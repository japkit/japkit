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
	 * By default, this method annotation is active an will generate a method.
	 * To switch it on or of case by case, a Matcher can be used here. The
	 * element on which the matcher is applied is the annotated class.
	 * 
	 * @return
	 */
	Matcher[] activation() default {};
	
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
	_Annotation[] annotations() default {};

	

	@interface List {
		DelegateMethods[] value();
	}
}
