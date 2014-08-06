package de.stefanocke.japkit.processor

import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.support.MethodRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class MethodGenerator extends MemberGeneratorSupport implements MemberGenerator {

	override getSupportedMetaAnnotation() {
		Method.name
	}
	
	override createMemberRule(TypeElement membersClass, AnnotationMirror methodAnnotation) {
		new MethodRule(methodAnnotation, null)
	}

}
