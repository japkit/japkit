package de.stefanocke.japkit.support

import com.google.common.cache.CacheBuilder
import javax.lang.model.element.AnnotationMirror
import com.google.common.cache.Cache
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.metaannotations.Template
import de.stefanocke.japkit.metaannotations.Trigger
import java.util.IdentityHashMap
import java.util.Map

class RuleFactory {

	//Ist das legal? GGf. auf eine Runde beschränken...
	val matcherCache = new IdentityHashMap<AnnotationMirror, ElementMatcher>
	val matcherFactory = [AnnotationMirror am|new ElementMatcher(am)]

	def createElementMatcher(AnnotationMirror am) {
		getOrCreate(matcherCache, am, matcherFactory)
	}

	val annoRuleCache = new IdentityHashMap<AnnotationMirror, AnnotationMappingRule>
	val annoRuleFactory = [AnnotationMirror am|new AnnotationMappingRule(am)]

	def createAnnotationMappingRule(AnnotationMirror am) {
		getOrCreate(annoRuleCache, am, annoRuleFactory)
	}

	val templateCache = new IdentityHashMap<TypeElement, TemplateRule>
	
	def templateFactory(AnnotationMirror templateAnnotation) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		[TypeElement templateClass|new TemplateRule(templateClass, templateAnnotation ?: templateClass.annotationMirror(Template))]
	}

	def createTemplateRule(TypeElement templateClass) {
		//let the rule find the @Template annotation
		createTemplateRule(templateClass, null)
	}
	
	def createTemplateRule(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		getOrCreate(templateCache, templateClass, templateFactory(templateAnnotation))
	}
	
	val triggerAnnotationCache = new IdentityHashMap<TypeElement, TriggerAnnotationRule>
	
	def createTriggerAnnotationRule(TypeElement triggerAnnotationClass){
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		getOrCreate(triggerAnnotationCache, triggerAnnotationClass, [new TriggerAnnotationRule(triggerAnnotationClass.annotationMirror(Trigger), triggerAnnotationClass)])
	}

	def static <K, V> V getOrCreate(Map<K, V> cache, K key, (K)=>V factory) {
		cache.get(key) ?: {
			val v = factory.apply(key)
			cache.put(key, v)
			v
		}
	}
}
