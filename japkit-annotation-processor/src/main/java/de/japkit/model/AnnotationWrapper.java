package de.japkit.model;

import javax.lang.model.element.AnnotationMirror;

/**
 * Interface for classes that wrap an AnnotationMirror.
 * 
 * @author stefan
 */
public interface AnnotationWrapper extends AnnotationMirror {

	/**
	 * @return the wrapped Annotation
	 */
	AnnotationMirror getAnnotation();
}
