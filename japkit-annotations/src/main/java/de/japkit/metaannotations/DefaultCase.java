package de.japkit.metaannotations;

/**
 * Like {@link Case}, but wiht a condition that always evaluates to true. Should be placed at last position within a Switch.
 * 
 * @author stefan
 *
 */
public @interface DefaultCase {
	
	String value() default "";
	
	String valueLang() default "";
	
	Class<?>[] valueFun() default {};
}
