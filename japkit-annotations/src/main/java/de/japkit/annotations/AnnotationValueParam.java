package de.japkit.annotations;

import java.lang.annotation.Annotation;
import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import de.japkit.metaannotations.DefaultAnnotation;

/**
 * If an parameter is annotated with this annotation, the according annotation value is "injected" into the parameter
 * when a call to the method is generated.
 * 
 * @author stefan
 *
 */
@Target(ElementType.PARAMETER)
public @interface AnnotationValueParam {
	Class<? extends Annotation> annotation() default DefaultAnnotation.class;
}
