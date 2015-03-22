package de.stefanocke.japkit.rules

import de.stefanocke.japkit.metaannotations.CodeFragment
import de.stefanocke.japkit.metaannotations.Function
import de.stefanocke.japkit.metaannotations.Library
import de.stefanocke.japkit.metaannotations.Matcher
import de.stefanocke.japkit.metaannotations.Properties
import de.stefanocke.japkit.metaannotations.Template
import de.stefanocke.japkit.metaannotations.Trigger
import de.stefanocke.japkit.metaannotations.TypeQuery
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector
import de.stefanocke.japkit.services.ElementsExtensions
import de.stefanocke.japkit.services.ExtensionRegistry
import java.lang.annotation.Annotation
import java.util.HashMap
import java.util.IdentityHashMap
import java.util.List
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.metaannotations.Switch

class RuleFactory {
	
	def clearCaches(){
		matcherCache.clear
		annoRuleCache.clear
		templateCache.clear
		libraryCache.clear
		functionCache.clear
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
	
	
	val libraryCache = new HashMap<TypeElement, LibraryRule>
	
	def createLibraryRule(TypeElement libraryClass){
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		getOrCreate(libraryCache, libraryClass, [new LibraryRule(libraryClass.annotationMirror(Library), libraryClass)])
	}
	
	
	val functionCache = new HashMap<Element, Rule>
	
	/**
	 * Creates a function rule if the element has a function annotation. Otherwise returns null.
	 */
	def createFunctionRule(Element element){
		getOrCreate(functionCache, element, [createFunctionInternal(element)])
	}
	
	private static val List<Pair<Class<? extends Annotation>, (AnnotationMirror, Element)=>AbstractRule>> 
		functionFactories = #[
			CodeFragment->[am, e | new CodeFragmentRule(am, e)],
			Function->[am, e | new FunctionRule(am, e)],
			Matcher->[am, e | new ElementMatcher(am, e)],
			TypeQuery->[am, e | new TypeQueryRule(am, e)],
			ClassSelector->[am, e | new TypeRule(am, e)],
			Properties->[am, e | new PropertyFilter(am, e)],
			Switch->[am, e | new SwitchRule(am, e)]
		]
	
	def private createFunctionInternal(Element element){
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		val factory = functionFactories.map[element.annotationMirror(key)->value].findFirst[key!=null]
		factory?.value?.apply(factory.key, element)
	}
	

	def static <K, V> V getOrCreate(Map<K, V> cache, K key, (K,(V)=>void)=>V factory) {
		cache.get(key) ?: {
			if(cache.containsKey(key)) return null; //support caching null values
			val v = factory.apply(key, [V v | cache.put(key, v)])
			cache.put(key, v)
			v
		}
	}
}
