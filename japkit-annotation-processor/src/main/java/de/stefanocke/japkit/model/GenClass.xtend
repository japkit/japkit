package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import de.stefanocke.japkit.rules.ExtensionRegistry
import de.stefanocke.japkit.rules.TypesExtensions
import javax.lang.model.element.TypeElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenClass extends GenTypeElement implements TypeElement{
	public static val kind = CLASS	
	
	override getSuperclass(){
		super.superclass ?: ExtensionRegistry.get(TypesExtensions).javaLangObject
	}
	
}