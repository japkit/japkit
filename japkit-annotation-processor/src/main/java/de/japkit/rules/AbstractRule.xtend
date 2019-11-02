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

	def protected <T> T inRule((Object)=>T closure){
		
		pushCurrentRule(this)
		try{
			handleException(null, null) [
				metaElement?.registerMetaTypeElement
				
				closure.apply(null)				
			]	
		} finally{
			popCurrentRule
		}
	}
	
	/**
	 * Convenience method to create a RuleException. Makes sure that the correct metaAnnotation of the rule is included. This is especially important
	 * if the exception occurs in rule constructor, since there is no "rule context" yet when it is called.
	 */
	def protected RuleException ruleException(String msg) {
		new RuleException(msg, metaAnnotation, null);		
	}
	
	/**
	 * Convenience method to create a RuleException. Makes sure that the correct metaAnnotation of the rule is included. This is especially important
	 * if the exception occurs in rule constructor, since there is no "rule context" yet when it is called.
	 */
	def protected RuleException ruleException(String msg, String avName) {
		new RuleException(msg, metaAnnotation, avName);		
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