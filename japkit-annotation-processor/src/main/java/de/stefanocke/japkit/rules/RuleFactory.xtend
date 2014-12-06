package de.stefanocke.japkit.rules

import de.stefanocke.japkit.metaannotations.Template
import de.stefanocke.japkit.metaannotations.Trigger
import de.stefanocke.japkit.services.ElementsExtensions
import de.stefanocke.japkit.services.ExtensionRegistry
import java.util.HashMap
import java.util.IdentityHashMap
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

class RuleFactory {
	
	def clearCaches(){
		matcherCache.clear
		annoRuleCache.clear
		templateCache.clear
		libraryCache.clear
	}

	//TODO: Bringt das hier überhaupt etwas, wenn der AnnotationMirror ohnehin jedes mal unterschiedlich ist?
	//Reicht das Template caching nicht bereits aus?
	val matcherCache = new IdentityHashMap<AnnotationMirror, ElementMatcher>
	val matcherFactory = [AnnotationMirror am, (ElementMatcher)=>void registrationCallBack |new ElementMatcher(am)]

	def createElementMatcher(AnnotationMirror am) {
		getOrCreate(matcherCache, am, matcherFactory)
	}

	//TODO: Bringt das hier überhaupt etwas, wenn der AnnotationMirror ohnehin jedes mal unterschiedlich ist?
	//Reicht das Template caching nicht bereits aus?
	val annoRuleCache = new IdentityHashMap<AnnotationMirror, AnnotationMappingRule>
	val annoRuleFactory = [AnnotationMirror am, (AnnotationMappingRule)=>void registrationCallBack |new AnnotationMappingRule(am)]

	def createAnnotationMappingRule(AnnotationMirror am) {
		getOrCreate(annoRuleCache, am, annoRuleFactory)
	}

	val templateCache = new HashMap<String, TemplateRule>
	
	def templateFactory(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		[String templateClassFqn,(TemplateRule)=>void registrationCallBack |
			new TemplateRule(templateClass, templateAnnotation ?: templateClass.annotationMirror(Template), registrationCallBack)
		]
	}

	def createTemplateRule(TypeElement templateClass) {
		//let the rule find the @Template annotation
		createTemplateRule(templateClass, null)
	}
	
	def createTemplateRule(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		getOrCreate(templateCache, templateClass.qualifiedName.toString, templateFactory(templateClass, templateAnnotation))
	}
	
	val triggerAnnotationCache = new IdentityHashMap<TypeElement, TriggerAnnotationRule>
	
	def createTriggerAnnotationRule(TypeElement triggerAnnotationClass){
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		getOrCreate(triggerAnnotationCache, triggerAnnotationClass, [new TriggerAnnotationRule(triggerAnnotationClass.annotationMirror(Trigger), triggerAnnotationClass)])
	}
	
	
	val libraryCache = new IdentityHashMap<TypeElement, LibraryRule>
	
	def createLibraryRule(TypeElement libraryClass){
		getOrCreate(libraryCache, libraryClass, [new LibraryRule(null as AnnotationMirror, libraryClass)])
	}
	

	def static <K, V> V getOrCreate(Map<K, V> cache, K key, (K,(V)=>void)=>V factory) {
		cache.get(key) ?: {
			val v = factory.apply(key, [V v | cache.put(key, v)])
			cache.put(key, v)
			v
		}
	}
}
