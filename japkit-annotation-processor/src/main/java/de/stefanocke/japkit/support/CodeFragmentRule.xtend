package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

@Data
class CodeFragmentRule extends CodeRule {
	
	//val 
	//	val active = activation.nullOrEmpty || activation.exists[matches(ruleSrcElement)]
	
	ElementMatcher[] activation
	
	new(AnnotationMirror metaAnnotation) {
		super(metaAnnotation, '')
		_activation = metaAnnotation.elementMatchers("activation", null)
	}
	
	override CharSequence code(Element ruleSrcElement){
		val rse = ruleSrcElement ?: getCurrentRuleSrcElement
		if(activation.nullOrEmpty || activation.exists[matches(rse)]){		
			super.code(rse)	
		} else ''
	}
	
	def CharSequence surround(CharSequence surrounded){
		surround(getCurrentRuleSrcElement, surrounded)
	}
	
	def CharSequence surround(Element ruleSrcElement, CharSequence surrounded){
		try{
			valueStack.put("surrounded", surrounded)
			val result = code(ruleSrcElement ?: getCurrentRuleSrcElement)
			if(result == null || result.length == 0) surrounded else result
		} finally {
			valueStack.remove("surrounded")
		}
	}
	
}