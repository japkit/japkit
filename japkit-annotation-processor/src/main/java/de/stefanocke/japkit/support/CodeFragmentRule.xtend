package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import java.util.List

@Data
class CodeFragmentRule extends CodeRule implements ICodeFragmentRule {
	
	ElementMatcher[] activation
	((Object)=>CharSequence)=>List<CharSequence> scopeRule
	
	new(AnnotationMirror metaAnnotation, Element metaElement) {
		super(metaAnnotation, metaElement, '')
		_activation = metaAnnotation.elementMatchers("activation")
		_scopeRule = createScopeRule(metaAnnotation, metaElement, null)
	}
	
	override CharSequence code(){
		scopeRule.apply[
			if(activation.nullOrEmpty || activation.exists[matches(currentSrcElement)]){		
				super.code()	
			} else ''		
		].head    //TODO: use scope for iteration instead of "bodyIterator" ? 
	}
	
	
	override CharSequence surround(CharSequence surrounded){
		scopeRule.apply[
			valueStack.put("surrounded", surrounded)
			val result = code()
			if(result == null || result.length == 0) surrounded else result
		].head    //TODO: use scope for iteration instead of "bodyIterator" ? 
	}
	
}