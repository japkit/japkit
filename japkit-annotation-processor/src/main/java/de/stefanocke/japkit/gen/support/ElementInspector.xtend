package de.stefanocke.japkit.gen.support

import javax.lang.model.element.Element
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.TypeVariable
import javax.lang.model.element.TypeElement
import java.util.Set
import javax.lang.model.element.TypeParameterElement

class ElementInspector {
	
	val Set<TypeParameterElement> typeParams = newHashSet();
	
	val Set<TypeVariable> typeVars = newHashSet();
	
	def CharSequence print(Element e){
		'''«e.summary» asType: «e.asType.printType»
				«e.details»
			«FOR ee : e.enclosedElements BEFORE '{' AFTER '}'»
				«ee.print»
			«ENDFOR»
			
		'''
	}
	
	def dispatch details(Element element){
		''''''
	}
	
	def dispatch details(TypeParameterElement element){

	}
	
	def dispatch details(TypeElement element){
		(element.asType as DeclaredType).typeArguments.map[it as TypeVariable].forEach(v | typeVars.add(v))
		'''TypeParameters: {
			«FOR tp : element.typeParameters»
				«tp.print» generic: «tp.genericElement.summary»
				«typeParams.add(tp)»
			«ENDFOR»
		}'''
		
	}
	
	def CharSequence summary(Element e){
		'''«e» «e.kind» «System.identityHashCode(e)»'''
	}
	
	def dispatch CharSequence printType(TypeMirror type){
		 '''«type.typeSummary»'''
	}
	
	def dispatch CharSequence printType(DeclaredType type){
		 '''«type.typeSummary» typeArguments: «FOR ta : type.typeArguments»«ta.printType»«ENDFOR»'''
	}
	
	def dispatch CharSequence printType(TypeVariable type){
		 '''«type.typeSummary» varIsInSet: «typeVars.contains(type)» asElement: «type.asElement.summary»  isInSet: «typeParams.contains(type.asElement)»'''
	}
	
	def private typeSummary(TypeMirror type){
		'''«type» «type.kind» «System.identityHashCode(type)»'''
	}
	
	
	
}