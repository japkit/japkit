package de.japkit.metaannotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

/**
 * Java does not support nullable annotation values.
 * By defining an annotation value as an array and annotating it with @SingleValue, nullable AVs can be emulated.
 * The AV is considered to be null, if the array is empty. Furthermore, when retrieving the value in expressions, it will 
 * never be an array but always a single value.
 * 
 * @author stefan
 *
 */
@Target(ElementType.METHOD)
public @interface SingleValue {

}
