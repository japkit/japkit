package de.japkit.annotations;

import java.lang.annotation.Annotation;

/** Marks an annotation as a template for generating another annotation. */
public @interface AnnotationTemplate {
	/**
	 * 
	 * @return the annotation to be generated.
	 */
	Class<? extends Annotation> targetAnnotation();
}
