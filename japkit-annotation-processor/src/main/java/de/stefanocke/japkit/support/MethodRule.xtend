package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenParameter
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.type.TypeMirror

@Data
class MethodRule extends ExecutableElementRule<GenMethod> {

	
	(Element)=>TypeMirror returnTypeRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		_returnTypeRule = createReturnTypeRule
	}
	
	new((Element)=>boolean activationRule, (Element)=>Iterable<? extends Element> srcElementsRule,
		(Element)=>String nameRule, (Element)=>Set<Modifier> modifiersRule,
		(Element)=>List<? extends AnnotationMirror> annotationsRule,
		(Element)=>List<? extends GenParameter> paramRules, (GenMethod, Element)=>CharSequence codeRule,
		(Element)=>TypeMirror returnTypeRule) {
		super(activationRule, srcElementsRule, nameRule, modifiersRule, annotationsRule, paramRules, codeRule)
		_returnTypeRule = returnTypeRule ?: [null]
	}
	
	
	new(AnnotationMirror metaAnnotation, String avPrefix, (Element)=>Iterable<? extends Element> srcElementsRule,
		(Element)=>String nameRule, (Element)=>List<? extends GenParameter> paramRules,
		(GenMethod, Element)=>CharSequence codeRule, (Element)=>TypeMirror returnTypeRule) {
		super(metaAnnotation, avPrefix, srcElementsRule, nameRule, paramRules, codeRule)	
		_returnTypeRule = returnTypeRule ?: [null]
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
