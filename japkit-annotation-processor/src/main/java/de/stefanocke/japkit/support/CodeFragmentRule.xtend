package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror

@Data
class CodeFragmentRule extends CodeRule {
	
	ElementMatcher[] activation
	
	new(AnnotationMirror metaAnnotation) {
		super(metaAnnotation, '')
		_activation = metaAnnotation.elementMatchers("activation", null)
	}
	
	override CharSequence code(){
		if(activation.nullOrEmpty || activation.exists[matches(currentSrcElement)]){		
			super.code()	
		} else ''
	}
	
	
	def CharSequence surround(CharSequence surrounded){
		try{
			valueStack.put("surrounded", surrounded)
			val result = code()
			if(result == null || result.length == 0) surrounded else result
		} finally {
			valueStack.remove("surrounded")
		}
	}
	
}