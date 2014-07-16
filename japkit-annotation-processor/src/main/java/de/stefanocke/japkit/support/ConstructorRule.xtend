package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenConstructor
import de.stefanocke.japkit.gen.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement

class ConstructorRule extends ExecutableElementRule {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}

	protected override createMember(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		val ctor = createMemberAndSetCommonAttributes(triggerAnnotation, annotatedClass, generatedClass,
			ruleSrcElement, [new GenConstructor])


		ctor.parameters = generateParameters( triggerAnnotation, annotatedClass, generatedClass, ruleSrcElement)

		val codeBody = bodyCodeRule.getAsCodeBody(ctor)
		if (codeBody != null) {
			ctor.body = codeBody
		}
		ctor
	}

	

}
