package de.stefanocke.japkit.support.el

import java.lang.RuntimeException

class ELProviderException extends RuntimeException {
	new(Throwable t){
		super(t.message, t)
	}
	
	new(String msg){
		super(msg)
	} 
	
}