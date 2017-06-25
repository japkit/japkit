package de.japkit.rules

import de.japkit.metaannotations.CodeFragment
import de.japkit.metaannotations.Function
import de.japkit.metaannotations.Library
import de.japkit.metaannotations.Matcher
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
import de.japkit.metaannotations.And
import de.japkit.metaannotations.Or
import de.japkit.metaannotations.Not
import de.japkit.services.MessageCollector
import de.japkit.metaannotations.Clazz
import de.japkit.metaannotations.InnerClass

class RuleFactory {
	
	val MessageCollector mc = ExtensionRegistry.get(MessageCollector)
	
	def clearCaches(){
		matcherCache.clear
		templateCache.clear
		libraryCache.clear
		functionCache.clear
		triggerAnnotationCache.clear
	}

	//TODO: Bringt das hier überhaupt etwas, wenn der AnnotationMirror ohnehin jedes mal unterschiedlich ist?
	//Reicht das Template caching nicht bereits aus?
	val matcherCache = new IdentityHashMap<AnnotationMirror, MatcherRule>
	val matcherFactory = [AnnotationMirror am, (MatcherRule)=>void registrationCallBack |new MatcherRule(am)]

	def createMatcherRule(AnnotationMirror am) {
		getOrCreate(matcherCache, am, matcherFactory)
	}


	val templateCache = new HashMap<String, TemplateRule>
	
	def templateFactory(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		[String templateClassFqn,(TemplateRule)=>void registrationCallBack |
			mc.printDiagnosticMessage['''Create TemplateRule from «templateClass»'''];
			//Always try to find Template annotation. Only if not found, use given annotation (@Class, @InnerClass)
			new TemplateRule(templateClass, templateClass.annotationMirror(Template) ?:templateAnnotation, registrationCallBack)
		]
	}

	def createTemplateRule(TypeElement templateClass) {
		//let the rule find the @Template annotation
		createTemplateRule(templateClass, null)
	}
	
	def createTemplateRule(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		getOrCreate(templateCache, templateClass.qualifiedName.toString, templateFactory(templateClass, templateAnnotation))
	}
	
	val triggerAnnotationCache = new HashMap<String, TriggerAnnotationRule>
	
	def createTriggerAnnotationRule(TypeElement triggerAnnotationClass){
		
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		getOrCreate(triggerAnnotationCache, triggerAnnotationClass.qualifiedName.toString, [
			mc.printDiagnosticMessage['''Create TriggerAnnotationRule from «triggerAnnotationClass»'''];
			new TriggerAnnotationRule(triggerAnnotationClass.annotationMirror(Trigger), triggerAnnotationClass)
		])
	}
	
	
	val libraryCache = new HashMap<TypeElement, LibraryRule>
	
	def createLibraryRule(TypeElement libraryClass){
		
		
		getOrCreate(libraryCache, libraryClass, [
			mc.printDiagnosticMessage['''Create LibraryRule from «libraryClass»'''];
			new LibraryRule(libraryClass.findLibraryAnnotation, libraryClass)
		])
	}
	
	def findLibraryAnnotation(TypeElement libraryClass) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		#[Library, Clazz, InnerClass, Template].map[libraryClass.annotationMirror(it)].findFirst[it !== null]
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
			Matcher->[am, e | new MatcherRule(am, e)],
			TypeQuery->[am, e | new TypeQueryRule(am, e)],
			ClassSelector->[am, e | new ClassSelectorRule(am, e)],
			Switch->[am, e | new SwitchRule(am, e)],
			Var->[am, e | new ELVariableRule(am, e)],
			And->[am, e | new BooleanOperatorRule(am, e, false, false)],
			Or->[am, e | new BooleanOperatorRule(am, e, false, true)],
			Not->[am, e | new BooleanOperatorRule(am, e, true, true)]
		]
	
	def private createFunctionInternal(Element element){
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		val factory = functionFactories.map[element.annotationMirror(key)->value].findFirst[key !== null]
		factory?.value?.apply(factory.key, element)
	}
	

	def static <K, V> V getOrCreate(Map<K, V> cache, K key, (K,(V)=>void)=>V factory) {
		val v = cache.get(key) ?: {
			try {
				if(cache.containsKey(key)) return null; //support caching null values
				val v = factory.apply(key, [V v | cache.put(key, v)])
				cache.put(key, v)
				v 
			} catch (Exception e) {
				ExtensionRegistry.get(MessageCollector).printDiagnosticMessage['''Exception whe creating Rule for «key»: «e»'''];
				//Delete potential early registration if there was an exception during creation
				cache.remove(key);
				throw e
			}
		}
		v
	}
}
