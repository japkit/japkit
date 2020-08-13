package de.japkit.model;

/**
 * Interface for generating code for method bodies and field initializers.
 * 
 * @author stefan
 */
public interface CodeBody {
	/**
	 * Generates the code for a method body or field initializer.
	 * 
	 * @param emitterContext the context of the current emitter allows to deal
	 *            with imports.
	 * @return the code
	 */
	CharSequence code(EmitterContext emitterContext);
}
