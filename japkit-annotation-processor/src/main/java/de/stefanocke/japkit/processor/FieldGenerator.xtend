package de.stefanocke.japkit.processor

import de.stefanocke.japkit.metaannotations.Field
import de.stefanocke.japkit.support.FieldRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class FieldGenerator extends MemberGeneratorSupport implements MemberGenerator {
	

	override getSupportedMetaAnnotation() {
		Field.name
	}
	
	override createMemberRule(TypeElement membersClass, AnnotationMirror fieldAnnotation) {
		new FieldRule(fieldAnnotation, null)
	}

}
