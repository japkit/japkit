package de.japkit.metaannotations;

import javax.lang.model.element.Modifier;

public @interface Setter {
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
	
	Modifier[] modifiers() default { Modifier.PUBLIC };

	Annotation[] annotations() default {};
	
	Annotation[] paramAnnotationMappings() default {};
	
	/**
	 * 
	 * @return true means, the "set" prefix is omitted.
	 */
	boolean fluent() default false;
	
	/**
	 * 
	 * @return true means, the setter returns 'this' to allow for chaining.
	 */
	boolean chain() default false;
	
	/**
	 * Names of code fragments to surround the assignment expression.
	 */
	String[] surroundAssignmentExprFragments() default {};
	
	/**
	 * 
	 * @return names of the fragments to surround the generated code body.
	 */
	String[] surroundingFragments() default{};
	
	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code body.
	 */
	String[] beforeFragments() default{};
	
	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code body.
	 */
	String[] afterFragments() default{};
	
	
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
}
