package de.stefanocke.japkit.el

class ELProviderException extends RuntimeException {
	new(Throwable t){
		super(t.message, t)
	}
	
	new(String msg){
		super(msg)
	} 
	
}