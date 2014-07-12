package de.stefanocke.japkit.support

import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

@Data
class CodeFragmentRules {
	val List<CodeFragmentRule> rules
	
	new(Iterable<AnnotationMirror> metaAnnotations){
		_rules = metaAnnotations.map[new CodeFragmentRule(it)].toList
	} 
	
	def code(){
		rules.map[code].join
	}
	
	def code(Element ruleSrcElement){
		rules.map[code(ruleSrcElement)].join
	}
}