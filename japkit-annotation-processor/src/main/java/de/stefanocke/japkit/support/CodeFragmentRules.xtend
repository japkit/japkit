package de.stefanocke.japkit.support

import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ValueStack
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

@Data
class CodeFragmentRules {
	val List<CodeFragmentRule> rules
	
	new(Iterable<AnnotationMirror> metaAnnotations){
		_rules = metaAnnotations.map[new CodeFragmentRule(it)].toList
	} 
	
	def currentValueStack() {
		ExtensionRegistry.get(ELSupport).valueStack
	}
	
	def code(){
		code(currentValueStack())
	}	
	
	def code(ValueStack vs){
		rules.map[code(vs)].join
	}
	
	def code(Element ruleSrcElement){
		code(currentValueStack(), ruleSrcElement)
	}
	
	def code(ValueStack vs, Element ruleSrcElement){
		rules.map[code(vs, ruleSrcElement)].join
	}
	
	def CharSequence surround(CharSequence surrounded){
		surround(currentValueStack, surrounded)
	}
	
	def CharSequence surround(ValueStack vs, CharSequence surrounded){
		surround(vs, null as Element, surrounded)
	}
	
	def CharSequence surround(Element ruleSrcElement, CharSequence surrounded){
		surround(currentValueStack, ruleSrcElement, surrounded)
	}
	
	def CharSequence surround(ValueStack vs, Element ruleSrcElement, CharSequence surrounded){
		var result = surrounded
		for(r : rules) {
			result = r.surround(vs, ruleSrcElement, result)
		}
		result
	}
	
	def static CharSequence surround(ValueStack vs,String fragmentName, CharSequence surrounded){
		surround(vs, fragmentName, null, surrounded)
	
	}
	
	def static CharSequence surround(ValueStack vs, String fragmentName, Element ruleSrcElement, CharSequence surrounded){
		val fragments = vs.get(fragmentName, CodeFragmentRules)
		if(fragments == null) surrounded else fragments.surround(vs, ruleSrcElement, surrounded)
	
	}
}