package de.japkit.rules

import de.japkit.model.GenConstructor
import de.japkit.model.GenElement
import de.japkit.model.GenParameter
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.type.TypeMirror

class ConstructorRule extends ExecutableElementRule<GenConstructor> {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}
	
	new(()=>boolean activationRule, ()=>Iterable<? extends Object> srcRule,
		()=>Set<Modifier> modifiersRule,
		(GenElement)=>List<? extends AnnotationMirror> annotationsRule, ()=>CharSequence commentRule,
		()=>List<? extends GenParameter> paramRules, (GenConstructor)=>CharSequence codeRule,
		()=>TypeMirror returnTypeRule) {
		super(activationRule, srcRule, RuleUtils.NO_NAME, modifiersRule, annotationsRule, commentRule, paramRules, codeRule)
	}
	
	override protected createMember(String name) {
		new GenConstructor
	}
	
	override protected createNameRule() {
		RuleUtils.NO_NAME
	}

	

}
