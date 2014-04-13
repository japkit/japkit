package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.activeannotations.Required

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
	
}