package de.stefanocke.japkit.services

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data

/**
 * An exception that prevents further processing of an annotation. Should be catched by the processor and reported as error
 * at an appropriate location.
 */
@Data
@Deprecated
class ProcessingException extends RuntimeException {
	Element element
	AnnotationMirror annotationMirror
	CharSequence annotationValueName
	AnnotationValue annotationValue
	
	new (String message, Element element, AnnotationMirror annotationMirror, CharSequence annotationValueName, AnnotationValue annotationValue){
		super(message)
		this.element = element
		this.annotationMirror = annotationMirror
		this.annotationValueName = annotationValueName
		this.annotationValue = annotationValue
	}
	
	new (String message, Element element){
		this(message, element, null, null, null)
	}
	
}