package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.support.MethodRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import java.util.Set

class MethodGenerator extends MemberGeneratorSupport implements MemberGenerator {
	

	override createMembers(TypeElement membersClass, TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation,
		AnnotationMirror methodAnnotation) {
		
		//TODO: Cache MethodRules by methodAnnotation
		new MethodRule(methodAnnotation, null).apply(annotatedClass, generatedClass, triggerAnnotation, generatedClass)
	}

	override getSupportedMetaAnnotation() {
		Method.name
	}

}
