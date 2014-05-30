package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Template
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

//TODO: Verallgemeinern!  Aus so einem Template kann man auch Felder, Annotationen, Initializers, interfaces usw. kopieren!
class FromTemplateGenerator extends MemberGeneratorSupport implements MemberGenerator {

	override createMembers(TypeElement templateClass, TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation,
		AnnotationMirror templateAnnotation) {

		printDiagnosticMessage['''Process Java template «templateClass»''']

		createTemplateRule(templateClass, templateAnnotation).apply(annotatedClass, generatedClass, triggerAnnotation)
	}

	override getSupportedMetaAnnotation() {
		Template.name
	}

}
