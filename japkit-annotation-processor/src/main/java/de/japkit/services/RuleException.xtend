package de.japkit.services

import java.lang.RuntimeException
import org.eclipse.xtend.lib.annotations.Data

/** Exception for errors that occured when processing a rule */
@Data
class RuleException extends RuntimeException {
	new(String message){
		super(message)
	}		
}