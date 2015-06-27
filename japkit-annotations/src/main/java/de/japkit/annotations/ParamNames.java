package de.japkit.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;


/**
 * Unfortunately, Eclipse does not always provide parameter names during incremental build, since types
 * that are not root elements of current round are provided as binary type bindings. We fix the parameter names,
 * if the method has a ParamNames annotation.
 */
@Target({ElementType.CONSTRUCTOR, ElementType.METHOD})
public @interface ParamNames {
	String[] value() default {};
}
