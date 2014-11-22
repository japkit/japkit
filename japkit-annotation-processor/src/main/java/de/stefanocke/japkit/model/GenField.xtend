package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.VariableElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenField extends GenVariableElement implements VariableElement{
	public static val kind = FIELD	
	
	//static val modifiers_default = #{Modifier.PRIVATE}	
	
	var CodeBody constantExpr
	
	def CodeBody getConstantExpr(){
		this.constantExpr
	}
	
	def setConstantExpr(CodeBody constantExpr){
		this.constantExpr = constantExpr
	}
	
}