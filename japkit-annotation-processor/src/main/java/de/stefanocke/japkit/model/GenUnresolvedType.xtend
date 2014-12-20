package de.stefanocke.japkit.model

import javax.lang.model.type.ErrorType

/**
 * A type that has been created during code generation but that could not be resolved so far, sine the type element is not available or
 * has not been generated yet.
 */
public class GenUnresolvedType extends GenDeclaredType implements ErrorType {

	private String qualifiedName_;
	private String simpleName_;
	
	//true, if it's known to be an inner class. False if it is not known or it is not an inner class.
	private boolean innerClass;
	
	new(String qualifiedName, boolean innerClass) {
		super(null);
		this.qualifiedName_ = qualifiedName
		this.simpleName_ = qualifiedName.substring(qualifiedName.lastIndexOf('.')+1)
		this.innerClass = innerClass
	}
	
	override qualifiedName() {
		this.qualifiedName_
	}
	
	override simpleName() {
		this.simpleName_
	}
	
	def getEnclosingQualifiedName(){
		qualifiedName.substring(0, qualifiedName.lastIndexOf('.'))
	}
	
	override erasure() {
		if(typeArguments.nullOrEmpty) this else
			new GenUnresolvedType(qualifiedName_, innerClass)
	}
	
	def boolean isInnerClass(){
		innerClass
	}

}