package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.CodeBody
import de.stefanocke.japkit.model.GenElement
import de.stefanocke.japkit.model.GenExecutableElement
import de.stefanocke.japkit.model.GenParameter
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import org.eclipse.xtend.lib.annotations.Data

@Data
abstract class ExecutableElementRule<G extends GenExecutableElement> extends MemberRuleSupport<ExecutableElement, G> {

	
	()=>List<? extends GenParameter> paramRules
	
	(G)=>CodeBody codeBodyRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		paramRules = createParamRules
		codeBodyRule = createCodeBodyRule 
	}
	
	new(()=>boolean activationRule, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>Set<Modifier> modifiersRule,
		(GenElement)=>List<? extends AnnotationMirror> annotationsRule, ()=>CharSequence commentRule,
		()=>List<? extends GenParameter> paramRules, (G)=>CharSequence codeRule) {
		super(activationRule, srcRule, nameRule, modifiersRule, annotationsRule, commentRule)
		
		this.paramRules = paramRules ?: [|emptyList]
		codeBodyRule = CodeRule.createCodeBodyRule(codeRule as (GenElement)=>CharSequence, null)
	}
	
	new(AnnotationMirror metaAnnotation, String avPrefix, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>CharSequence commentRule, ()=>List<? extends GenParameter> paramRules,
		(G)=>CharSequence codeRule) {
		super(metaAnnotation, avPrefix, srcRule, nameRule, commentRule)
		this.paramRules = paramRules ?: [|emptyList]
		val defaultFragments = CodeFragmentRules.createDefaultFragmentsRule(metaAnnotation, avPrefix)
		codeBodyRule = CodeRule.createCodeBodyRule(codeRule as (GenElement)=>CharSequence, defaultFragments)
	}
	
	protected override applyRulesAfterCreation(G member) {
		super.applyRulesAfterCreation(member)
		member.parameters = paramRules.apply		
		member.body = codeBodyRule.apply(member)
	}
	
	def protected (G)=>CodeBody createCodeBodyRule(){
		val cr = new CodeRule(metaAnnotation, template, "body");
		[genElement | CodeRule.getAsCodeBody(genElement, cr)]
	}
	
	
	def protected ()=>List<? extends GenParameter>  createParamRules(){
		createParamRules(metaAnnotation, template, avPrefix)
	}
	
	
}