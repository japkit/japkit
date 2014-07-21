package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenExecutableElement
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.support.el.ValueStack
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import de.stefanocke.japkit.gen.GenElement

@Data
abstract class ExecutableElementRule<G extends GenExecutableElement> extends MemberRuleSupport<ExecutableElement, G> {

	
	(Element)=>List<? extends GenParameter> paramRules
	
	(G, Element)=>CodeBody codeBodyRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		_paramRules = createParamRules
		_codeBodyRule = createCodeBodyRule 
	}
	
	new((Element)=>boolean activationRule, (Element)=>Iterable<? extends Element> srcElementsRule,
		(Element)=>String nameRule, (Element)=>Set<Modifier> modifiersRule,
		(Element)=>List<? extends AnnotationMirror> annotationsRule,
		(Element)=>List<? extends GenParameter> paramRules, (G, Element)=>CharSequence codeRule) {
		super(activationRule, srcElementsRule, nameRule, modifiersRule, annotationsRule)
		
		_paramRules = paramRules ?: [emptyList]
		_codeBodyRule = [genElement, ruleSourceElement | 
			CodeRule.getAsCodeBody(genElement, ruleSourceElement, codeRule as (GenElement, Element)=>CharSequence)
		]
	}
	
	protected override applyRulesAfterCreation(G member, Element ruleSrcElement) {
		super.applyRulesAfterCreation(member, ruleSrcElement)
		member.parameters = _paramRules.apply(ruleSrcElement)
		
		member.body = _codeBodyRule.apply(member, ruleSrcElement)
	}
	
	def protected (G, Element)=>CodeBody createCodeBodyRule(){
		val cr = new CodeRule(metaAnnotation, "body");
		[genElement, ruleSourceElement | CodeRule.getAsCodeBody(genElement, ruleSourceElement, cr)]
	}
	
	
	def protected (Element)=>List<? extends GenParameter>  createParamRules(){
		ru.createParamRules(metaAnnotation, template, avPrefix)
	}
	
	
	
	
}