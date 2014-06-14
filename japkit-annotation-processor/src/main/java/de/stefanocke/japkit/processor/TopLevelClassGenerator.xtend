package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.GenerateClass
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class TopLevelClassGenerator extends ClassGeneratorSupport{
	

	def GenTypeElement processGenClassAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation, Set<GenTypeElement> generatedClasses) {

		val genClass = triggerAnnotation.metaAnnotation(GenerateClass)
		if(genClass == null) return null;
		
		val GenTypeElement enclosingClass = null
	
		generateClass(annotatedClass, enclosingClass, triggerAnnotation, genClass, generatedClasses)
	}
		
}
