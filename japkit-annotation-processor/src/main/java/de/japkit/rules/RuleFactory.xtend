package de.japkit.rules

import de.japkit.metaannotations.CodeFragment
import de.japkit.metaannotations.Function
import de.japkit.metaannotations.Library
import de.japkit.metaannotations.Matcher
import de.japkit.metaannotations.Properties
import de.japkit.metaannotations.Template
import de.japkit.metaannotations.Trigger
import de.japkit.metaannotations.TypeQuery
import de.japkit.metaannotations.classselectors.ClassSelector
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import java.lang.annotation.Annotation
import java.util.HashMap
import java.util.IdentityHashMap
import java.util.List
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import de.japkit.metaannotations.Switch
import de.japkit.metaannotations.Var

class RuleFactory {
	
	def clearCaches(){
		matcherCache.clear
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
	
	
	val functionCache = new HashMap<Element, IParameterlessFunctionRule<?>>
	
	/**
	 * Creates a function rule if the element has a function annotation. Otherwise returns null.
	 */
	def createFunctionRule(Element element){
		getOrCreate(functionCache, element, [createFunctionInternal(element)])
	}
	
	private static val List<Pair<Class<? extends Annotation>, (AnnotationMirror, Element)=>IParameterlessFunctionRule<?>>> 
		functionFactories = #[
			CodeFragment->[am, e | new CodeFragmentRule(am, e)],
			Function->[am, e | new FunctionRule(am, e)],
			Matcher->[am, e | new ElementMatcher(am, e)],
			TypeQuery->[am, e | new TypeQueryRule(am, e)],
			ClassSelector->[am, e | new TypeRule(am, e)],
			Properties->[am, e | new PropertyFilter(am, e)],
			Switch->[am, e | new SwitchRule(am, e)],
			Var->[am, e | new ELVariableRule(am, e)]
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
