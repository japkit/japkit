package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.TypesExtensions
import javax.lang.model.element.TypeElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenClass extends GenTypeElement implements TypeElement{
	public static val kind = CLASS	
	
	override getSuperclass(){
		super.superclass ?: ExtensionRegistry.get(TypesExtensions).OBJECT
	}
	
}