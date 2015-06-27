package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import de.japkit.activeannotations.Required
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

@FieldsFromInterface
abstract class GenVariableElement extends GenElement implements VariableElement{
	@Required
	private TypeMirror type;
	
	Object constantValue
	
	override asType() {
		return type;
	}
	
	def void setType(TypeMirror type){
		this.type = type
	}
	
	override void resolveContainedTypeVariables(GenParameterizable parameterizable){		
			type = parameterizable.resolveTypeVariables(type)
	}
	
	//Not for code gen!
	override toString() {
		'''«type» «simpleName»'''
	}
	
}