package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import de.japkit.services.MessageCollector
import de.japkit.services.TypesExtensions
import de.japkit.services.TypesRegistry
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import de.japkit.services.RuleException

@Data
abstract class AbstractRule implements Rule {
	val transient protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val transient protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient protected extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val transient protected extension RuleUtils = ExtensionRegistry.get(RuleUtils)
	val transient protected extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val transient protected extension ELSupport = ExtensionRegistry.get(ELSupport)
	val transient protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val transient protected extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	
	AnnotationMirror metaAnnotation
	Element metaElement
	RuleException[] ruleCreationException = #[null]; 
	
	
	def protected <T> T inRule((Object)=>T closure){
		
		pushCurrentRule(this)
		try{
			handleException(null, null) [
				//Throw Exceptions during rule creation here to get proper error reporting
				if(ruleCreationException.get(0) !== null){
					throw ruleCreationException.get(0);
				}
				metaElement?.registerMetaTypeElement
				
				closure.apply(null)				
			]	
		} finally{
			popCurrentRule
		}
	}
	
	def protected void throwRuleCreationException(String msg) {
		ruleCreationException.set(0, new RuleException(msg));		
	}
	
	def protected void throwRuleCreationException(String msg, String avName) {
		ruleCreationException.set(0, new RuleException(msg, avName));		
	}
	
	//registers the dependency from the rule's meta type element to the current trigger annotation.
	//This is necessary to determine the classes to re-generate, when a meta type element.
	//A more appropriate place for this registration would be at construction time, but due to rule caching and reuse,
	//several triggers could share the same meta-type elements...
	
	def void registerMetaTypeElement(Element element) {
		if(element instanceof TypeElement && currentTriggerAnnotation  !== null){
			registerMetaTypeElement(element.topLevelEnclosingTypeElement, currentTriggerAnnotation.annotationAsTypeElement)			
		}
		
		
	}
	
}