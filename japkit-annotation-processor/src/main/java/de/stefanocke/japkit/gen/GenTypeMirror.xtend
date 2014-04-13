package de.stefanocke.japkit.gen

import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.type.TypeVisitor
import javax.lang.model.type.TypeKind

@FieldsFromInterface
abstract class GenTypeMirror implements TypeMirror {
	
	override abstract TypeKind getKind()
	
	override <R, P> accept(TypeVisitor<R,P> v, P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
}