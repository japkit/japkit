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
	
	def static CharSequence surround(String fragmentName, CharSequence surrounded){
		surround( fragmentName, null, surrounded)
	
	}
	
	def static CharSequence surround(String fragmentName, Element ruleSrcElement, CharSequence surrounded){
		val extension ElSupport = ExtensionRegistry.get(ELSupport)
		val fragments = valueStack.get(fragmentName, CodeFragmentRules)
		if(fragments == null) surrounded else fragments.surround(ruleSrcElement, surrounded)
	
	}
}