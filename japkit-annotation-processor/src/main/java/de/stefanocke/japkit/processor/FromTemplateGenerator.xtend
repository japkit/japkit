package de.stefanocke.japkit.processor

import de.stefanocke.japkit.metaannotations.Template
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class FromTemplateGenerator extends MemberGeneratorSupport implements MemberGenerator {


	override getSupportedMetaAnnotation() {
		Template.name
	}
	
	override createMemberRule(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		createTemplateRule(templateClass, templateAnnotation)
	}

}
