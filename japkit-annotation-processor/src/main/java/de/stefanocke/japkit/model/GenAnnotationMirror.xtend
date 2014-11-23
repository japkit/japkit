package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import de.stefanocke.japkit.activeannotations.Required
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.TypesExtensions
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror

@FieldsFromInterface
class GenAnnotationMirror implements AnnotationMirror {
	
	protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	
	@Required
	DeclaredType annotationType
	
	Map<ExecutableElement, GenAnnotationValue> elementValues = newHashMap
	
	def setValue(String name, (TypeMirror)=>GenAnnotationValue valueFactory){
		val exEl = getAVMethod(name, true)
		val v = valueFactory.apply(exEl.returnType)
		setValueInternal(exEl, v)
		
	}
		
	def setValue(String name, GenAnnotationValue v){
		val exEl = getAVMethod(name, true)
		setValueInternal(exEl, v)
		
	}
	
	def private setValueInternal(ExecutableElement exEl, GenAnnotationValue v) {
		if(v==null){
			elementValues.remove(exEl)
		} else {
			elementValues.put(exEl, v)
		}
	}
	
	def getValueWithoutDefault(String name){
		val exEl = getAVMethod(name, true)
		elementValues.get(exEl)
	}
	
	def ExecutableElement getAVMethod(String name, boolean required){
		val exEl = (annotationType.asElement as TypeElement).enclosedElements.filter[kind==ElementKind.METHOD]
			.map[it as ExecutableElement].findFirst[simpleName.contentEquals(name)]  //TODO: Caching!
		if(exEl==null && required){
			throw new IllegalArgumentException('''Annotation value '«name»' is not defined in annotation type «annotationType.qualifiedName»''')
		}
		exEl
	}
	
	
	
	def setElementValues(Map<? extends ExecutableElement,? extends AnnotationValue> elementValues) {
		throw new UnsupportedOperationException("Please use setValue instead")
	}
}