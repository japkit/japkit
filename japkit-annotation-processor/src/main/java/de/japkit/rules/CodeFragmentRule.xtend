package de.japkit.rules

import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data

@Data
class CodeFragmentRule extends CodeRule implements ICodeFragmentRule {
	
	()=>boolean activationRule
	((Object)=>CharSequence)=>List<CharSequence> scopeRule
	
	new(AnnotationMirror metaAnnotation, Element metaElement) {
		super(metaAnnotation, metaElement, '', '''/**Error in CodeFragement «metaAnnotation» «metaElement»*/''')
		activationRule = createActivationRule(metaAnnotation, null)
		scopeRule = createScopeRule(metaAnnotation, metaElement, false, null, false)  //scopeRule without own src rule and without iteration
	}
	
	
	override CharSequence code(){
		//val indentation = (valueStack.get("indentation") as CharSequence ?: '') + '\t'
		scopeRule.apply[
			if(activationRule.apply){				
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