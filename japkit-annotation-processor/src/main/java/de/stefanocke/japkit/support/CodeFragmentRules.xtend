package de.stefanocke.japkit.support

import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

import static extension de.stefanocke.japkit.support.RuleUtils.*

@Data
class CodeFragmentRules {
	val List<CodeFragmentRule> rules
	
	new(Iterable<AnnotationMirror> metaAnnotations){
		_rules = metaAnnotations.map[new CodeFragmentRule(it)].toList
	} 

	def code(){
		rules.map[it.code()].join
	}
		
	def code(Element ruleSrcElement){
		rules.map[it.code(ruleSrcElement)].join
	}
	
	
	def CharSequence surround(CharSequence surrounded){
		surround(null as Element, surrounded)
	}
	
	def CharSequence surround(Element ruleSrcElement, CharSequence surrounded){
		var result = surrounded
		for(r : rules) {
			result = r.surround(ruleSrcElement, result)
		}
		result
	}
	
	def static CharSequence surround(String[] fragmentNames, CharSequence surrounded){
		surround( fragmentNames, null, surrounded)
	
	}
	
	def static CharSequence surround(String[] fragmentNames, Element ruleSrcElement, CharSequence surrounded){
		if(fragmentNames==null) return surrounded
		val extension ElSupport = ExtensionRegistry.get(ELSupport)
		
		var result = surrounded
		for(n : fragmentNames) {
			val fragments = valueStack.getRequired(n) as  CodeFragmentRules
			result = fragments.surround(ruleSrcElement, surrounded)		
		}
		result
	
	}
	
	def static CharSequence code(String[] fragmentNames, Element ruleSrcElement){
		if(fragmentNames==null) return ''
		val extension ElSupport = ExtensionRegistry.get(ELSupport)
		
		fragmentNames.map[valueStack.getRequired(it) as  CodeFragmentRules].map[it.code(ruleSrcElement)].join
			
	}
	
	def static (Element, CharSequence)=>CharSequence createDefaultFragmentsRule(AnnotationMirror metaAnnotation, String avPrefix) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		val surroundingFragments = metaAnnotation.value("surroundingFragments".withPrefix(avPrefix), typeof(String[]))
		val beforeFragments = metaAnnotation.value("beforeFragments".withPrefix(avPrefix), typeof(String[]))
		val afterFragments = metaAnnotation.value("afterFragments".withPrefix(avPrefix), typeof(String[]));
		[ Element ruleSrcElement, CharSequence code |
			val before = CodeFragmentRules.code(beforeFragments, ruleSrcElement)
			val after = CodeFragmentRules.code(afterFragments, ruleSrcElement)
			CodeFragmentRules.surround(
				surroundingFragments,
				ruleSrcElement,
				'''«before»«code»«after»'''
			)
		]
	}
}