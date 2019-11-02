package de.japkit.services

import java.lang.RuntimeException
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.AnnotationMirror

/** Exception for errors that occured when processing a rule */
@Data
class RuleException extends RuntimeException {
	
	/**
	 * Optionally the name of the meta annotation value for which the error occured. 
	 */
	String metaAnnotationValueName;
	
	/**
	 * Optionally the meta annotation for which the error occured. 
	 */
	AnnotationMirror metaAnnotation;
	
	new(String message){
		this(message, null, null, null)
	}
	
	new(String message, String avName){
		this(message, null, avName, null)
	}
	
	new(String message, AnnotationMirror metaAnnotation, String metaAnnotationValueName){
		this(message,  metaAnnotation, metaAnnotationValueName, null)
	}
	
	new(String message, AnnotationMirror metaAnnotation, String metaAnnotationValueName, Throwable cause){
		super(message, cause)
		this.metaAnnotationValueName=metaAnnotationValueName
		this.metaAnnotation = metaAnnotation
	}
			
}