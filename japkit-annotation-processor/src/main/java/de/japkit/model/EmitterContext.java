package de.japkit.model;

import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeMirror;

/**
 * If the generated code somehow depends on emitter state, this is the callback
 * interface to get or set this state. Example: Register imports during code
 * generation.
 */
public interface EmitterContext {

	/**
	 * Returns the name of the type as it shall be used within the generated
	 * code. If possible, an import statement is added and the short type name
	 * is returned. If not possible the FQN is returned. Type parameters are
	 * ignored. Thus, this method shall be used for code that accesses the type
	 * in a static way, for example, accessing a static field of class.
	 * 
	 * @param type the type
	 * @return the type name as it shall be used within the generated code.
	 */
	CharSequence staticTypeRef(TypeMirror type);

	/**
	 * Returns the name of the type as it shall be used within the generated
	 * code. If possible, an import statement is added and the short type name
	 * is returned. If not possible the FQN is returned. This is applied
	 * recursively for type parameters as well.
	 * 
	 * @param type the type
	 * @return the type name as it shall be used within the generated code.
	 */
	CharSequence typeRef(TypeMirror type);

	/**
	 * Creates an import statement for the given type if it does not conflict
	 * with an existing one. Type parameters are ignored.
	 * 
	 * @param type the type
	 * @return true, if an import statement for that type has been created (now
	 *         or earlier). false, if not.
	 */
	boolean importIfPossible(DeclaredType type);
}
