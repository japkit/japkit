package de.japkit.metaannotations;

import javax.tools.Diagnostic.Kind;

public @interface Constraint {
	
	/**
	 * 
	 * @return the expression. Must be boolean. If it evaluates to false, the constraint is violated.
	 */
	String expr();
	
	/**
	 * 
	 * @return the message to be displayed if the constraint is violated. 
	 */
	String msg();
	
	/**
	 * 
	 * @return the severity for the message.
	 */
	Kind msgKind() default Kind.ERROR;
	
	/**
	 * 
	 * @return the language of the expression. Default is Java EL.
	 */
	String lang() default "";
}
