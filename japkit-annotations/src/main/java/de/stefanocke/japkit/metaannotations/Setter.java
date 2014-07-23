package de.stefanocke.japkit.metaannotations;

import javax.lang.model.element.Modifier;

public @interface Setter {
	Matcher[] activation() default {};
	
	Modifier[] modifiers() default { Modifier.PUBLIC };

	AnnotationMapping[] annotationMappings() default {};
	
	AnnotationMapping[] paramAnnotationMappings() default {};
	
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
