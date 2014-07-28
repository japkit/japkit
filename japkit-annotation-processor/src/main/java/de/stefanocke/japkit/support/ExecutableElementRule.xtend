package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExecutableElement
import de.stefanocke.japkit.gen.GenParameter
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier

@Data
abstract class ExecutableElementRule<G extends GenExecutableElement> extends MemberRuleSupport<ExecutableElement, G> {

	
	()=>List<? extends GenParameter> paramRules
	
	(G)=>CodeBody codeBodyRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		_paramRules = createParamRules
		_codeBodyRule = createCodeBodyRule 
	}
	
	new(()=>boolean activationRule, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>Set<Modifier> modifiersRule,
		(GenElement)=>List<? extends AnnotationMirror> annotationsRule, ()=>CharSequence commentRule,
		()=>List<? extends GenParameter> paramRules, (G)=>CharSequence codeRule) {
		super(activationRule, srcRule, nameRule, modifiersRule, annotationsRule, commentRule)
		
		_paramRules = paramRules ?: [|emptyList]
		_codeBodyRule = CodeRule.createCodeBodyRule(codeRule as (GenElement)=>CharSequence, null)
	}
	
	new(AnnotationMirror metaAnnotation, String avPrefix, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>CharSequence commentRule, ()=>List<? extends GenParameter> paramRules,
		(G)=>CharSequence codeRule) {
		super(metaAnnotation, avPrefix, srcRule, nameRule, commentRule)
		_paramRules = paramRules ?: [|emptyList]
		val defaultFragments = CodeFragmentRules.createDefaultFragmentsRule(metaAnnotation, avPrefix)
		_codeBodyRule = CodeRule.createCodeBodyRule(codeRule as (GenElement)=>CharSequence, defaultFragments)
	}
	
	protected override applyRulesAfterCreation(G member) {
		super.applyRulesAfterCreation(member)
		member.parameters = _paramRules.apply
		
		member.body = _codeBodyRule.apply(member)
	}
	
	def protected (G)=>CodeBody createCodeBodyRule(){
		val cr = new CodeRule(metaAnnotation, "body");
		[genElement | CodeRule.getAsCodeBody(genElement, cr)]
	}
	
	
	def protected ()=>List<? extends GenParameter>  createParamRules(){
		ru.createParamRules(metaAnnotation, template, avPrefix)
	}
	
	
	
	
}