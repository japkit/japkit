package de.stefanocke.japkit.support

import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import de.stefanocke.japkit.support.el.ElExtensions
import de.stefanocke.japkit.support.el.ELSupport

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
		val extension ElSupport = ExtensionRegistry.get(ELSupport)
		
		var result = surrounded
		for(n : fragmentNames) {
			val fragments = valueStack.getRequired(n) as  CodeFragmentRules
			result = fragments.surround(ruleSrcElement, surrounded)		
		}
		result
	
	}
}