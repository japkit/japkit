package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import de.japkit.services.ExtensionRegistry
import de.japkit.services.TypesExtensions
import javax.lang.model.element.TypeElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenClass extends GenTypeElement implements TypeElement{
	public static val kind = CLASS	
	
	override getSuperclass(){
		super.superclass ?: ExtensionRegistry.get(TypesExtensions).javaLangObject
	}
	
}