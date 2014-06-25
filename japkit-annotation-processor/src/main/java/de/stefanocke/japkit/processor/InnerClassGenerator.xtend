package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.InnerClass
import de.stefanocke.japkit.support.InnerClassRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class InnerClassGenerator implements MemberGenerator {
	
	override createMembers(TypeElement membersClass, TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation, AnnotationMirror metaAnnotationToBeProcessed) {
		
		//TODO: Rule Caching
		new InnerClassRule(metaAnnotationToBeProcessed, null).apply(annotatedClass, generatedClass, triggerAnnotation, generatedClass)
					
	}
	
	override getSupportedMetaAnnotation() {
		return InnerClass.name
	}
	
}