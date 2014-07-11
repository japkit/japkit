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
	
	override code(Element ruleSrcElement){
		if(activation.nullOrEmpty || activation.exists[matches(ruleSrcElement)]){		
			super.code(ruleSrcElement)	
		} else ''
	}
	
}