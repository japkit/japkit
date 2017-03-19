package de.japkit.el

/**
 * Exception that is thrown by EL-Providers if expression valuation fails.
 * The EL provider should only use this exception, if there is something wrong with the expression itself.
 * Exceptions that come from invoked methods shall not be wrapped by the EL Provider.
 * 
 */
class ELProviderException extends RuntimeException {
	new(Throwable t){
		super(t.message, t)
	}
	
	new(String msg){
		super(msg)
	} 
	
}