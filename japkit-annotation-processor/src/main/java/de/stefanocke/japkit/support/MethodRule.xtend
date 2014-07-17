package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenMethod
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.type.TypeMirror

@Data
class MethodRule extends ExecutableElementRule {

	(Element)=>TypeMirror returnTypeRule 
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		_returnTypeRule = ru.createTypeRule(metaAnnotation, template?.returnType, "return")
	}

	protected override createMember(Element ruleSrcElement) {
		val method = createMemberAndSetCommonAttributes(ruleSrcElement, [new GenMethod(it)])

		method.returnType = returnTypeRule.apply(ruleSrcElement)

		method.parameters = paramRules.apply(ruleSrcElement)

		val codeBody =  bodyCodeRule.getAsCodeBody(method)
		if (codeBody != null) {
			method.removeModifier(Modifier.ABSTRACT)
			method.body = codeBody
		}
		method
	}

	

}
