package de.japkit.metaannotations;

import java.lang.annotation.Documented;

/**
 * Like {@link Case}, but with a condition that always evaluates to true. Should
 * be placed at last position within a Switch.
 * 
 * @author stefan
 */
@Documented
public @interface DefaultCase {

	String value() default "";

	String valueLang() default "";

	Class<?>[] valueFun() default {};
}
