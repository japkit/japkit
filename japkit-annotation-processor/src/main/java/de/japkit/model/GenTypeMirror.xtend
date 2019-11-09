package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror

@FieldsFromInterface
abstract class GenTypeMirror extends GenAnnotatedConstruct implements TypeMirror {
	
	override abstract TypeKind getKind()
	
	
	
}