package de.stefanocke.japkit.support

import de.stefanocke.japkit.support.Rule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

@Data
class AbstractRule implements Rule {
	val protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	
	AnnotationMirror metaAnnotation
	Element metaElement
	
	
	def protected <T> T inRule((Object)=>T closure){
		
		try{
			pushCurrentRule(this)
			closure.apply(null)			
		} finally{
			popCurrentRule
		}
	}
}