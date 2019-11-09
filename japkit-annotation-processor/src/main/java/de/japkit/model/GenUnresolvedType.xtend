package de.japkit.model

import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeVisitor

/**
 * A type that has been created during code generation but that could not be resolved so far, sine the type element is not available or
 * has not been generated yet.
 */
class GenUnresolvedType extends GenDeclaredType implements ErrorType {

	String qualifiedName_;
	String simpleName_;
	
	//true, if it's known to be an inner class. False if it is not known or it is not an inner class.
	boolean innerClass;
	
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
	
	override <R, P> accept(TypeVisitor<R,P> v, P p) {
		v.visitError(this, p)
	}

}