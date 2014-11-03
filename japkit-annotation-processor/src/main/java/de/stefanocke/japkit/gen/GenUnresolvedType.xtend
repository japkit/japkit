package de.stefanocke.japkit.gen

import javax.lang.model.type.ErrorType

/**
 * A type that has been created during code generation but that could not be resolved so far, sine the type element is not available or
 * has not been generated yet.
 */
public class GenUnresolvedType extends GenDeclaredType implements ErrorType {

	private String qualifiedName_;
	private String simpleName_;
	
	new(String qualifiedName) {
		super(null);
		this.qualifiedName_ = qualifiedName
		this.simpleName_ = qualifiedName.substring(qualifiedName.lastIndexOf('.')+1)
	}
	
	override qualifiedName() {
		this.qualifiedName_
	}
	
	override simpleName() {
		this.simpleName_
	}
	
	override erasure() {
		if(typeArguments.nullOrEmpty) this else
			new GenUnresolvedType(qualifiedName_)
	}

}