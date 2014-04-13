package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import static javax.lang.model.element.ElementKind.*
import javax.lang.model.element.VariableElement

@FieldsFromInterface
class GenParameter extends GenVariableElement implements VariableElement{
	public static val kind = PARAMETER
	
	
}