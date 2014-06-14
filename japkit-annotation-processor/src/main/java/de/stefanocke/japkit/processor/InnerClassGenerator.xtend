package de.stefanocke.japkit.processor

import de.stefanocke.japkit.processor.ClassGeneratorSupport
import de.stefanocke.japkit.processor.MemberGenerator
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.gen.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import java.util.Set
import de.stefanocke.japkit.metaannotations.InnerClass

class InnerClassGenerator extends ClassGeneratorSupport implements MemberGenerator {
	
	override createMembers(TypeElement membersClass, TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation, AnnotationMirror metaAnnotationToBeProcessed, Set<GenTypeElement> generatedClasses) {
		
		valueStack.scope [  //create new scope to not overwrite "currentGenClass" on VS
			val innerClass = generateClass(annotatedClass, generatedClass, triggerAnnotation, metaAnnotationToBeProcessed, generatedClasses)
			generatedClass.add(innerClass)		
		]
	}
	
	override getSupportedMetaAnnotation() {
		return InnerClass.name
	}
	
}