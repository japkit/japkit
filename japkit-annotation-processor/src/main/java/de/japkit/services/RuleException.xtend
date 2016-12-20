package de.japkit.services

import java.lang.RuntimeException
import org.eclipse.xtend.lib.annotations.Data

/** Exception for errors that occured when processing a rule */
@Data
class RuleException extends RuntimeException {
	
	/**
	 * Optionally the name of the annotation value for which the error occured. 
	 */
	String avName;
	
	new(String message){
		this(message, null)
	}
	
	new(String message, String avName){
		super(message)
		this.avName=avName
	}
			
}