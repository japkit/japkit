package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import de.japkit.activeannotations.Required
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.ExecutableElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror

@FieldsFromInterface
class GenAnnotationMirror implements AnnotationMirror {
	
	protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	
	@Required
	DeclaredType annotationType
	
	Map<ExecutableElement, GenAnnotationValue> elementValues = newLinkedHashMap
	
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
		if(v === null){
			elementValues.remove(exEl)
		} else {
			elementValues.put(exEl, v)
		}
	}
	
	def getValueWithoutDefault(String name){
		val exEl = getAVMethod(name, true)
		elementValues.get(exEl)
	}
	
	
	
	def ExecutableElement getAVMethod(String name, boolean required) {
		getAVMethod(this, name) ?:
			if (required) {
				throw new IllegalArgumentException('''Annotation value '«name»' is not defined in annotation type «this.annotationAsTypeElement.qualifiedName»''')
			} else
				null
	}
		
	def setElementValues(Map<? extends ExecutableElement,? extends AnnotationValue> elementValues) {
		throw new UnsupportedOperationException("Please use setValue instead")
	}
}