package de.stefanocke.japkit.annotations;

import java.lang.annotation.Annotation;
import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import de.stefanocke.japkit.metaannotations.DefaultAnnotation;

/**
 * Annotates a method that should be called before a property value is set.
 * @author stefan
 *
 */
@Target(ElementType.METHOD)
public @interface BeforeSet {
	/**
	 * Only if this annotation is present on the property field, the annotated method is called.
	 *  
	 * 
	 * @return the annotation class. The default is, that no annotation must be present at all.
	 */
	Class<? extends Annotation> fieldAnnotation() default DefaultAnnotation.class;
	
	/**
	 * Only if the property has this type or one of its suptypes, the annotated method is called.
	 * @return
	 */
	Class<?> propertyType() default Object.class;
}
