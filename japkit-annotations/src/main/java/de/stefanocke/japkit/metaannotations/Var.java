package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Annotation;

public @interface Var {
	String name();

	/**
	 * If this is set, the current trigger annotation value with this name is
	 * retrieved. If it is set (TODO: What does this exactly mean?), it is used
	 * as value for the variable and the expression won't be evaluated.
	 * 
	 * @return the trigger annotation value name
	 */
	String triggerAV() default "";

	/**
	 * If this is true and {@link #triggerAV()} is set, the annotation value with
	 * that name in the shadow annotation will be set to the value of the EL
	 * Variable.
	 * TODO: Is the really a property of the Var?
	 * Maybe, we should support this only for the case, where the @Var annotation is put directly on the annotation value declaration.
	 * (This is nicer anyway...). But then there is the Eclipse-ordering issue again...
	 * 
	 * @return
	 */
	boolean setInShadowAnnotation() default false;

	String expr() default "";

	String lang() default "";

	Class<?> type() default Object.class;

	/**
	 * If this value is set, the expression is ignored and the variable is a
	 * list of properties instead, according to the given filter criteria.
	 * 
	 * @return
	 */
	Properties[] propertyFilter() default {};
	
	TypeQuery[] typeQuery() default {};
	
	/**
	 * If set, and expr is not set, this matcher is put on value stack for later re-use.
	 * If set, and expr is set, the matcher is applied to the result of expr and ther result is put on value stack. 
	 * Expr is supposed to be an element collection.
	 */
	Matcher[] matcher() default {};
	
	/**
	 * If set, and expr is not set, this switch is put on value stack for later re-use.
	 * @return
	 */
	Switch[] switcher() default {};
	
	/**
	 * If set, the according annotation of the result of the expression, property filter or type query is retrieved.
	 * This is possible for Elements, Collection of Elements, Types and collections of types.
	 * 
	 * @return
	 */
	Class<? extends Annotation>[] annotation() default {};

	@interface List {
		Var[] value();
	}
}
