package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import java.util.List
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0

import static extension de.japkit.rules.CodeRule.withLinebreak
import static extension de.japkit.rules.RuleUtils.*

@Data
class CodeFragmentRules implements Function0<CharSequence>, ICodeFragmentRule{
	val List<CodeFragmentRule> rules
	
	new(Iterable<AnnotationMirror> metaAnnotations){
		rules = metaAnnotations.map[new CodeFragmentRule(it, null)].toList
	} 

	override code(){
		rules.map[it.code()].join
	}
	
	override CharSequence surround(CharSequence surrounded){
		var result = surrounded
		for(r : rules) {
			result = r.surround(result)
		}
		result
	}
	
	
	def static CharSequence surround(String[] fragmentNames, CharSequence surrounded){
		if(fragmentNames === null) return surrounded
		val extension ElSupport = ExtensionRegistry.get(ELSupport)
		
		var result = surrounded
		for(n : fragmentNames) {
			val fragments = valueStack.getRequired(n) as  ICodeFragmentRule
			result = fragments.surround(result)		
		}
		result
	
	}
	
	def static CharSequence code(String[] fragmentNames){
		if(fragmentNames === null) return ''
		val extension ElSupport = ExtensionRegistry.get(ELSupport)
		
		fragmentNames.map[valueStack.getRequired(it) as ICodeFragmentRule].map[it.code].join
			
	}
	
	def static (CharSequence)=>CharSequence createDefaultFragmentsRule(AnnotationMirror metaAnnotation, String avPrefix) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		val surroundingFragments = metaAnnotation?.value("surroundingFragments".withPrefix(avPrefix), typeof(String[]))
		val beforeFragments = metaAnnotation?.value("beforeFragments".withPrefix(avPrefix), typeof(String[]))
		val afterFragments = metaAnnotation?.value("afterFragments".withPrefix(avPrefix), typeof(String[]));
		[ CharSequence code |
				
				val before = CodeFragmentRules.code(beforeFragments)
				val after = CodeFragmentRules.code(afterFragments)
				CodeFragmentRules.surround(
					surroundingFragments,
					'''«before.withLinebreak»«code.withLinebreak(!after.nullOrEmpty)»«after»'''
				)	
				

		]
	}
	
	def static nullOrEmpty(CharSequence cs){
		cs === null || cs.length ==0
	}
	
	override apply() {
		code()
	}
	
}