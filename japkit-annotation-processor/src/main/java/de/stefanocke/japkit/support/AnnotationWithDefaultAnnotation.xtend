package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import java.util.HashMap

@Data
class AnnotationWithDefaultAnnotation implements AnnotationMirror{
	AnnotationMirror annotation
	AnnotationMirror defaultAnnotation
	
	override getAnnotationType() {
		annotation.annotationType
	}
	
	override getElementValues() {
		val result = new HashMap(defaultAnnotation.elementValues)
		result.putAll(annotation.elementValues)
		result
	}
	
	def static createIfNecessary(AnnotationMirror annotation, AnnotationMirror defaultAnnotation){
		if(annotation!=null && defaultAnnotation!=null) new AnnotationWithDefaultAnnotation(annotation, defaultAnnotation)
			else annotation ?: defaultAnnotation
		
	}
	
}