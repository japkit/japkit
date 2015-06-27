package de.japkit.services

import java.lang.RuntimeException

/**
 * An exception which has already bean reported to the MessageCollector.
 * Used to avoid error flooding.
 */
class ReportedException extends RuntimeException {
	new(String msg){
		super(msg)
	}
	
	new(Throwable cause){
		super(cause.message, cause)
	}
}