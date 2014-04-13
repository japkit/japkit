package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element

/**
 * An exception that prevents further processing of an annotation. Should be catched by the processor and reported as error
 * at an appropriate location.
 */
@Data
class ProcessingException extends RuntimeException {
	Element element
	AnnotationMirror annotationMirror
	CharSequence annotationValueName
	AnnotationValue annotationValue
	
	new (String message, Element element, AnnotationMirror annotationMirror, CharSequence annotationValueName, AnnotationValue annotationValue){
		super(message)
		this._element = element
		this._annotationMirror = annotationMirror
		this._annotationValueName = annotationValueName
		this._annotationValue = annotationValue
	}
	
	new (String message, Element element){
		this(message, element, null, null, null)
	}
	
}