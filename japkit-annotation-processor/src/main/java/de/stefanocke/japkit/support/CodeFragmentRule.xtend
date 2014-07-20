package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import de.stefanocke.japkit.support.el.ValueStack

@Data
class CodeFragmentRule extends CodeRule {
	
	//val 
	//	val active = activation.nullOrEmpty || activation.exists[matches(ruleSrcElement)]
	
	ElementMatcher[] activation
	
	new(AnnotationMirror metaAnnotation) {
		super(metaAnnotation, '')
		_activation = metaAnnotation.elementMatchers("activation", null)
	}
	
	override CharSequence code(ValueStack vs, Element ruleSrcElement){
		val rse = ruleSrcElement ?: vs.getCurrentRuleSrcElement
		if(activation.nullOrEmpty || activation.exists[matches(rse)]){		
			super.code(vs, rse)	
		} else ''
	}
	
//	def CharSequence surround( CharSequence surrounded){
//		surround(valueStack, surrounded)
//	}
	
	def CharSequence surround(ValueStack vs, CharSequence surrounded){
		surround(vs, vs.getCurrentRuleSrcElement, surrounded)
	}
	
//	def CharSequence surround(Element ruleSrcElement, CharSequence surrounded){
//		surround(valueStack, ruleSrcElement, surrounded)
//	}
	
	def CharSequence surround(ValueStack vs, Element ruleSrcElement, CharSequence surrounded){
		try{
			vs.put("surrounded", surrounded)
			val result = code(vs, ruleSrcElement ?: vs.getCurrentRuleSrcElement)
			if(result == null || result.length == 0) surrounded else result
		} finally {
			valueStack.remove("surrounded")
		}
	}
	
}