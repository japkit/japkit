package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Annotation;

public @interface TypeQuery {
	/**
	 * The trigger annotation of the types to be found.
	 * 
	 * @return
	 */
	Class<? extends Annotation> annotation();

	/**
	 * true means, types where trigger annotation is a shadow annotation are
	 * found.
	 * 
	 * @return
	 */
	boolean shadow() default true;

	/**
	 * True means, one unique result shall be returned and is is an error , if
	 * multiple ones are found.
	 * 
	 * @return
	 */
	boolean unique() default false;

	/**
	 * If set, then this AV of the trigger annotation of a found type is used as
	 * filter criteria. Only if it is in the set of types given by forTypesExpr, the found type is included in the result.
	 * <p>
	 * For example, this allows to query like this:   
	 * 
	 * SELECT @Repository WHERE entity IN (...)
	 * 
	 * 
	 * @return
	 */
	String filterAV() default "";
	
	/**
	 * The expression for the "IN clause". Must yield a type or a collection of types
	 * @return
	 */
	String inExpr() default "";
	
	String inExprLang() default "";
}
