package de.japkit.services

import java.lang.RuntimeException
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.AnnotationMirror

/** 
 * An error that occured when accessing a certain Annotation or its values.
 * 
 */
@Data
class AnnotationException extends RuntimeException {
	
	/**
	 * Optionally, the name of the annotation value for which the error occurred. 
	 */
	String annotationValueName;
	
	/**
	 * The annotation for which the error occurred.
	 */
	AnnotationMirror annotation;
	
	new(String message, AnnotationMirror annotation, String annotationValueName){
		this(message, annotation, annotationValueName, null)
	}
	
	new(String message, AnnotationMirror annotation, String annotationValueName, Throwable cause){
		super(message, cause)
		this.annotationValueName=annotationValueName
		this.annotation = annotation
	}
			
}