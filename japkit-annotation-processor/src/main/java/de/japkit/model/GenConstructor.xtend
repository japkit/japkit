package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.ExecutableElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenConstructor extends GenExecutableElement implements ExecutableElement{
	public static val kind = CONSTRUCTOR
	
	public static val simpleName_default = "<init>"	
	
	
	
}