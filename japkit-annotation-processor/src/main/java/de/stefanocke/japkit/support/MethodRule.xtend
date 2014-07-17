package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror

@Data
class MethodRule extends ExecutableElementRule {

	(Element)=>TypeMirror returnTypeRule 
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		_returnTypeRule = ru.createTypeRule(metaAnnotation, template?.returnType, "return")
	}

	protected override createMember(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		val method = createMemberAndSetCommonAttributes(triggerAnnotation, annotatedClass, generatedClass,
			ruleSrcElement, [new GenMethod(it)])

		method.returnType = returnTypeRule.apply(ruleSrcElement)

		method.parameters = generateParameters(ruleSrcElement)

		val codeBody =  bodyCodeRule.getAsCodeBody(method)
		if (codeBody != null) {
			method.removeModifier(Modifier.ABSTRACT)
			method.body = codeBody
		}
		method
	}

	

}
