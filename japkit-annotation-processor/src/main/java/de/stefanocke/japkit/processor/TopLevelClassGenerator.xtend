package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.GenerateClass
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import java.util.List
import java.util.ArrayList

class TopLevelClassGenerator extends ClassGeneratorSupport{
	

	def Set<GenTypeElement> processGenClassAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation) {

		val genClass = triggerAnnotation.metaAnnotation(GenerateClass)
		if(genClass == null) return emptySet;
		
		//Supports ELVariables in the scope of the generated class.
		//Note: src expression is currently not supported in the annotation, since generating multiple classes is not supported
		//and would for instance be in conflict with ElementExtensions.generatedTypeElementAccordingToTriggerAnnotation 
		val scopeRule = createScopeRule(genClass, null)
	
		val generatedClasses = newHashSet
		
		scopeRule.apply[
			generateClass(annotatedClass, null, triggerAnnotation, genClass, null, null, generatedClasses)		
		]
		
		generatedClasses
	}
		
}
