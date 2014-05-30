package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Annotation;

/**
 * 
 * @author stefan
 *
 */
public @interface RequiredTriggerAnnotation {
	Class<? extends Annotation>[] value();
}
