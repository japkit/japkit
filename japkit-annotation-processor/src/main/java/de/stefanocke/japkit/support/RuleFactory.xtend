package de.stefanocke.japkit.support

import com.google.common.cache.CacheBuilder
import javax.lang.model.element.AnnotationMirror
import com.google.common.cache.Cache
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.metaannotations.Template

class RuleFactory {

	//Ist das legal? GGf. auf eine Runde beschränken...
	val matcherCache = CacheBuilder.newBuilder.maximumSize(100).weakKeys.<AnnotationMirror, ElementMatcher>build
	val matcherFactory = [AnnotationMirror am|new ElementMatcher(am)]

	def createElementMatcher(AnnotationMirror am) {
		getOrCreate(matcherCache, am, matcherFactory)
	}

	val annoRuleCache = CacheBuilder.newBuilder.maximumSize(100).weakKeys.<AnnotationMirror, AnnotationMappingRule>build
	val annoRuleFactory = [AnnotationMirror am|new AnnotationMappingRule(am)]

	def createAnnotationMappingRule(AnnotationMirror am) {
		getOrCreate(annoRuleCache, am, annoRuleFactory)
	}

	val templateCache = CacheBuilder.newBuilder.maximumSize(100).weakKeys.<TypeElement, TemplateRule>build
	
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
	
	val triggerAnnotationCache = CacheBuilder.newBuilder.maximumSize(100).weakKeys.<TypeElement, TriggerAnnotationRule>build
	
	def createTriggerAnnotationRule(TypeElement triggerAnnotationClass){
		getOrCreate(triggerAnnotationCache, triggerAnnotationClass, [new TriggerAnnotationRule(triggerAnnotationClass)])
	}

	def static <K, V> V getOrCreate(Cache<K, V> cache, K key, (K)=>V factory) {
		cache.getIfPresent(key) ?: {
			val v = factory.apply(key)
			cache.put(key, v)
			v
		}
	}
}
