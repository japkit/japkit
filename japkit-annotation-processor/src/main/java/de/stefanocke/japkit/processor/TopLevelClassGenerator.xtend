package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.GenerateClass
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class TopLevelClassGenerator extends ClassGeneratorSupport{
	

	def Set<GenTypeElement> processGenClassAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation) {

		val genClass = triggerAnnotation.metaAnnotation(GenerateClass)
		if(genClass == null) return emptySet;
		
		val GenTypeElement enclosingClass = null
	
		generateClass(annotatedClass, enclosingClass, triggerAnnotation, genClass)
	}
		
}
