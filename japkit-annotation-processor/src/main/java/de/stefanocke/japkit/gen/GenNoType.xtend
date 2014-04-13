package de.stefanocke.japkit.gen

import javax.lang.model.type.NoType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeVisitor

class GenNoType  implements NoType {
	
	
	public static val INSTANCE = new GenNoType
	
	override <R,P> accept(TypeVisitor<R, P> v, P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override getKind() {
		TypeKind.NONE
	}
	
	override toString(){
		'void'
	}
	
}