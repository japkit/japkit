package de.stefanocke.japkit.model;

import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeMirror;

/**
 * RFU: If the generated code somwhow depends on emitter state, this is the callback interface to get or set this state.
 * Example: Register imports during code generation.
 */
public interface EmitterContext {
	
	CharSequence staticTypeRef(TypeMirror type);
			
	CharSequence staticTypeRef(Class<?> clazz);
	
	CharSequence typeRef(TypeMirror type);
	
	/**
	 * Creates an import statement for the given type if it does not conflict with an existing one.
	 * Type parameters are ignored.
	 * @param type the type
	 * @return true, if an import statement for that type has been created (now or earlier). false, if not.
	 */
	boolean importIfPossible(DeclaredType type);
}
