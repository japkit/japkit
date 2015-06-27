package de.japkit.el;

import de.japkit.services.ReportedException;

/**
 * This exception is put as value on the value stack, when there was an error during evaluation of an EL variable.
 * @author stefan
 *
 */
public class ElVariableError extends ReportedException {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	private String varName;

	public ElVariableError(String varName) {
		super("There was an error when evaluating EL variable "+varName);
		this.varName = varName;
	}

	public String getVarName() {
		return varName;
	}
	
	

}
