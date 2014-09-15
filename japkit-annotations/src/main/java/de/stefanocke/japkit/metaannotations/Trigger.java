package de.stefanocke.japkit.metaannotations;

import static java.lang.annotation.ElementType.ANNOTATION_TYPE;

import java.lang.annotation.Target;

/**
 * Marks an annotation type as trigger annotation.
 * 
 * 
 *  
 * @author stefan
 *
 */
@Target(value = ANNOTATION_TYPE)
public @interface Trigger {
	
	/**
	 * EL Variables in the scope of the annotated class. 
	 * @return
	 */
	Var[] vars() default {};
}
