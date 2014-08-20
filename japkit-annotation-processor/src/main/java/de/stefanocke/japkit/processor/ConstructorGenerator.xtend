package de.stefanocke.japkit.processor

import de.stefanocke.japkit.metaannotations.Constructor
import de.stefanocke.japkit.support.ConstructorRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class ConstructorGenerator extends MemberGeneratorSupport implements MemberGenerator {

	override getSupportedMetaAnnotation() {
		Constructor.name
	}
	
	override createMemberRule(TypeElement membersClass, AnnotationMirror methodAnnotation) {
		new ConstructorRule(methodAnnotation, null)
	}

}
