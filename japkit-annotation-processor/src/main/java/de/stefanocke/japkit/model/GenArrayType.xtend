package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import de.stefanocke.japkit.activeannotations.Required
import javax.lang.model.type.ArrayType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror

@FieldsFromInterface
class GenArrayType extends GenTypeMirror implements ArrayType {
	public static val kind = TypeKind.ARRAY
	

	@Required
	TypeMirror componentType

	
	override toString(){
		'''«componentType» []'''
	}	

}