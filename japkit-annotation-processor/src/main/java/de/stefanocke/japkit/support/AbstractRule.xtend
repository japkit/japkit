package de.stefanocke.japkit.support

import de.stefanocke.japkit.support.Rule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement

@Data
class AbstractRule implements Rule {
	val protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val protected extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	
	AnnotationMirror metaAnnotation
	Element metaElement
	
	
	def protected <T> T inRule((Object)=>T closure){
		
		pushCurrentRule(this)
		try{
			metaElement?.registerMetaTypeElement
			
			closure.apply(null)			
		} finally{
			popCurrentRule
		}
	}
	
	//registers the dependency from the rule's meta type element to the current trigger annotation.
	//This is necessary to determine the classes to re-generate, when a meta type element.
	//A more appropriate place for this registration would be at construction time, but due to rule caching and reuse,
	//several triggers could share the same meta-type elements...
	
	def void registerMetaTypeElement(Element element) {
		if(element instanceof TypeElement && currentTriggerAnnotation !=null){
			registerMetaTypeElement(element.topLevelEnclosingTypeElement, currentTriggerAnnotation.annotationAsTypeElement)			
		}
		
		
	}
	
}