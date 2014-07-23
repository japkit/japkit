package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenConstructor
import de.stefanocke.japkit.gen.GenParameter
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.type.TypeMirror

class ConstructorRule extends ExecutableElementRule<GenConstructor> {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}
	
	new((Element)=>boolean activationRule, (Element)=>Iterable<? extends Element> srcElementsRule,
		(Element)=>Set<Modifier> modifiersRule,
		(Element)=>List<? extends AnnotationMirror> annotationsRule, (Element)=>CharSequence commentRule,
		(Element)=>List<? extends GenParameter> paramRules, (GenConstructor, Element)=>CharSequence codeRule,
		(Element)=>TypeMirror returnTypeRule) {
		super(activationRule, srcElementsRule, RuleUtils.NO_NAME, modifiersRule, annotationsRule, commentRule, paramRules, codeRule)
	}
	
	override protected createMember(Element ruleSrcElement, String name) {
		new GenConstructor
	}
	
	override protected createNameRule() {
		RuleUtils.NO_NAME
	}

	

}
