package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import de.japkit.activeannotations.Required
import java.util.List
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.TypeVisitor

@FieldsFromInterface
class GenDeclaredType extends GenTypeMirror implements DeclaredType {
	public static val kind = TypeKind.DECLARED
	
	@Required
	private TypeElement element
	
	TypeMirror enclosingType
	
	List<TypeMirror> typeArguments = newArrayList()
	
	override asElement() {
		element
	}
	
	override toString(){
		'''«qualifiedName»«FOR a : typeArguments BEFORE '<' SEPARATOR ','  AFTER '>'»«a»«ENDFOR»'''
	}
	
	def qualifiedName(){
		element.qualifiedName.toString
	}
	
	def simpleName(){
		element.simpleName.toString
	}
	
	new(TypeElement element){
		this.element = element
	}
	
	new(TypeElement element, (GenDeclaredType)=>void initializer){
		this.element = element
		initializer.apply(this)
	}
	
	def erasure(){
		new GenDeclaredType(element)
	}
	
	override <R, P> accept(TypeVisitor<R,P> v, P p) {
		v.visitDeclared(this, p)
	}
}