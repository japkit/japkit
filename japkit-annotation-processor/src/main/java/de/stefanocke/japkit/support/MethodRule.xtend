package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement

class MethodRule extends ExecutableElementRule {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}

	protected override createMember(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		val method = createMemberAndSetCommonAttributes(triggerAnnotation, annotatedClass, generatedClass,
			ruleSrcElement, [new GenMethod(it)])

		method.returnType = typeFromMetaAnnotationOrTemplate(annotatedClass, generatedClass, triggerAnnotation,
			"returnType", "returnTypeArgs", ruleSrcElement, method.returnType)

		setParametersFromMetaAnnotation(method, triggerAnnotation, annotatedClass, generatedClass, ruleSrcElement)

		val codeBody = getCodeBodyFromMetaAnnotation(method, triggerAnnotation, "body" )
		if (codeBody != null) {
			method.removeModifier(Modifier.ABSTRACT)
			method.body = codeBody
		}
		method
	}

	

}
