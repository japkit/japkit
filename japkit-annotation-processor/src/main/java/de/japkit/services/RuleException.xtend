package de.japkit.services

import java.lang.RuntimeException
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.AnnotationMirror

/** Exception for errors that occured when processing a rule */
@Data
class RuleException extends RuntimeException {
	
	/**
	 * Optionally the name of the annotation value for which the error occured. 
	 */
	String avName;
	
	/**
	 * Optionally the annotation mirror for which the error occured. 
	 */
	AnnotationMirror annotation;
	
	new(String message){
		this(message, null, null)
	}
	
	new(String message, String avName){
		this(message, null, avName)
	}
	
	new(String message, AnnotationMirror annotation, String avName){
		super(message)
		this.avName=avName
		this.annotation = annotation
	}
			
}