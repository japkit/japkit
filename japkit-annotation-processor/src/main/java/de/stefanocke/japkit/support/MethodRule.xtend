package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenMethod
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.type.TypeMirror

@Data
class MethodRule extends ExecutableElementRule<GenMethod> {

	
	(Element)=>TypeMirror returnTypeRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		_returnTypeRule = createReturnTypeRule
	}
	
	def createReturnTypeRule() {
		ru.createTypeRule(metaAnnotation, template?.returnType, "return")
	}

	protected override createMember(Element ruleSrcElement, String name) {
		new GenMethod(name)
	}
	
	protected override applyRulesAfterCreation(GenMethod member, Element ruleSrcElement) {
		super.applyRulesAfterCreation(member, ruleSrcElement)
		member.returnType = returnTypeRule.apply(ruleSrcElement)
	}
	
	

	

}
