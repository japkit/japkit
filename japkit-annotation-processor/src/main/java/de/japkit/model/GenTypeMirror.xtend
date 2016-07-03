package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.TypeVisitor

@FieldsFromInterface
abstract class GenTypeMirror extends GenAnnotatedConstruct implements TypeMirror {
	
	override abstract TypeKind getKind()
	
	override <R, P> accept(TypeVisitor<R,P> v, P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
}