package de.stefanocke.japkit.support.el

import com.google.common.base.Stopwatch
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.PropertyFilter
import de.stefanocke.japkit.support.RuleFactory
import de.stefanocke.japkit.support.TypeElementNotFoundException
import de.stefanocke.japkit.support.TypesExtensions
import de.stefanocke.japkit.support.TypesRegistry
import de.stefanocke.japkit.util.MoreCollectionExtensions
import java.io.Writer
import java.net.URL
import java.util.ArrayList
import java.util.Collections
import java.util.Map
import java.util.ServiceLoader
import java.util.concurrent.TimeUnit
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*
import de.stefanocke.japkit.support.SwitchRule

class ELSupport {
	val extension ElementsExtensions elements = ExtensionRegistry.get(ElementsExtensions)

	extension TypesExtensions types = ExtensionRegistry.get(TypesExtensions)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)

	val Map<String, ELProvider> elProviders = newHashMap

	val Map<String, ELProvider> templateProviders = newHashMap

	val ELProvider defaultElProvider

	val defaultLanguage = "JavaEL"

	//The tread local value stack.
	def getValueStack() {
		ExtensionRegistry.get(ValueStack, [|new ValueStack(#{"elements" -> elements, "types" -> types}, null)])
	}

	new() {
		val sw = Stopwatch.createStarted
		try {
			printDiagnosticMessage[
				'''Searching EL-Providers using classloader «ELProvider.classLoader». Context CL: «Thread.currentThread.
					contextClassLoader»''']
			ServiceLoader.load(ELProvider, ELProvider.classLoader).forEach [
				val provider = it
				provider.supportedLanguages.forEach [
					elProviders.put(it, provider)
				]
				provider.supportedTemplateLanguages.forEach [
					templateProviders.put(it, provider)
				]
			]

		} catch (Throwable t) {
			throw new RuntimeException('''Error when loading EL-Providers: «t.message»''', t)
		}

		printDiagnosticMessage['''Init EL-Providers: «sw.elapsed(TimeUnit.MILLISECONDS)»''']

		defaultElProvider = elProviders.get(defaultLanguage)
	}

	def <T> T scope(ValueStack vs, Element e, (ValueStack)=>T closure) {
		try {
			vs.push
			vs.put("element", e)
			closure.apply(vs)

		} finally {
			vs.pop
		}
	}

	def void scope(ValueStack vs, Element e, (ValueStack)=>void closure) {
		try {
			vs.push
			vs.put("element", e)
			closure.apply(vs)

		} finally {
			vs.pop
		}
	}

	def <T> T eval(Element ruleSourceElement, String expr, String lang, Class<T> expectedType, CharSequence errorMessage,
		T errorResult) {
		valueStack.scope(ruleSourceElement) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
			eval(valueStack, expr, lang, expectedType, errorMessage, errorResult)
		]
	}

	def <T> T eval(ValueStack valueStack, String expr, String lang, Class<T> expectedType, CharSequence errorMessage,
		T errorResult) {
		try {
			return eval(valueStack, expr, lang, expectedType)	as T
		} catch (TypeElementNotFoundException tenfe) {
			throw tenfe
		} catch (Exception e) {
			reportError('''«errorMessage»: «e.message» EL expression: «expr»''', valueStack.get("element") as Element,
				null, null)
			errorResult
		}
	}

	//
	def <T> T eval(Element ruleSourceElement, String expr, String lang, Class<T> expectedType) {
		valueStack.scope(ruleSourceElement) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
			eval(it, expr, lang, expectedType)
		]
	}

	def <T> T eval(ValueStack valueStack, String expr, String lang, Class<T> expectedType) {

		//nicht schön hier.
		putShadowAnnotation(valueStack)

		return getElProvider(lang).eval(valueStack as Map<String, Object>, expr, expectedType, lang)	as T
	}

	//nicht schön hier.
	def putShadowAnnotation(ValueStack valueStack) {
		val currAnno = valueStack.get("currentAnnotation") as AnnotationMirror
		if (currAnno != null) {
			valueStack.put("shadowAnnotation",
				currentGeneratedClass?.annotationMirror(currAnno.annotationAsTypeElement.qualifiedName))
		}
	}

	def getElProvider(String lang) {
		val p = elProviders.get(if(lang.nullOrEmpty) defaultLanguage else lang)
		if(p == null) throw new ELProviderException('''No ELProvider found for language «lang»''')
		p
	}

	def write(Writer writer, URL templateUrl, String templateLanguage, Long templateLastModified) {
		write(valueStack, writer, templateUrl, templateLanguage, templateLastModified)
	}

	def write(ValueStack valueStack, Writer writer, URL templateUrl, String templateLanguage, Long templateLastModified) {
		getTemplateProvider(templateLanguage).write(writer, templateUrl, valueStack, templateLanguage,
			templateLastModified)
	}

	def getTemplateProvider(String lang) {
		val p = templateProviders.get(lang)
		if(p == null) throw new ELProviderException('''No ELProvider found for template language «lang»''')
		p
	}

	def void putELVariables(Element element, AnnotationMirror triggerAnnotation, AnnotationMirror elVarsAnnotation) {
		valueStack.putELVariables(element, triggerAnnotation, elVarsAnnotation)
	}

	def void putELVariables(ValueStack vs, Element element, AnnotationMirror triggerAnnotation,
		AnnotationMirror elVarsAnnotation) {
		elVarsAnnotation?.value("vars", typeof(AnnotationMirror[]))?.forEach [
			vs.putELVariable(element, triggerAnnotation, it)
		]
	}

	def Map<String, Object> getVariablesForShadowAnnotation(ValueStack vs) {
		getOrCreate(vs, "variablesForShadowAnnotation", [newHashMap])
	}

	def void putELVariable(ValueStack vs, Element element, AnnotationMirror triggerAnnotation,
		AnnotationMirror elVarAnnotation) {

		//TODO: Wenn wir hier auch eine Möglichkeit zum Override vorsehen wollen, dann muss die Trigger Annotation mit reingegeben werden
		//ELVariable ist dann die Meta-Annotation.
		val name = elVarAnnotation.value("name", String);
		val avName = elVarAnnotation.value("triggerAV", String);
		val expr = elVarAnnotation.value("expr", String);
		val lang = elVarAnnotation.value("lang", String);
		val type = Class.forName(elVarAnnotation.value("type", TypeMirror).asElement.qualifiedName.toString);

		val setInShadowAnnotation = elVarAnnotation.value("setInShadowAnnotation", Boolean);

		//TODO: Use Rule factory. But this is not possible, if we use triggerAnnotation. Reconsider...
		val propertyFilters = elVarAnnotation.value("propertyFilter", typeof(AnnotationMirror[]))?.map[
			new PropertyFilter(triggerAnnotation, it)];

		val typeQuery = elVarAnnotation.value("typeQuery", AnnotationMirror)
		
		val annotationToRetrieve = elVarAnnotation.value("annotation", TypeMirror) 
		
		val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
		val matcher = elVarAnnotation.value("matcher", typeof(AnnotationMirror[])).map[createElementMatcher].singleValue  
		
		//TODO: Use Rulefactory
		val switcher = elVarAnnotation.value("switcher", typeof(AnnotationMirror[])).map[new SwitchRule(it)].singleValue

		pushCurrentMetaAnnotation(elVarAnnotation)
		try {

			var Object av
			val value = if (!avName.nullOrEmpty && {
					av = currentAnnotation.value(avName, type);
					!av.nullOrEmptyAV
				}) {

					av

				} else if (!expr.nullOrEmpty) {
					val exprResult = vs.scope(element) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
						eval(vs, expr, lang, type);
					]
					if(matcher!=null){
						if(exprResult instanceof Iterable<?>){
							matcher.filter(exprResult as Iterable<?>)	
						} else {
							throw new IllegalArgumentException('''If expr and matcher are set, expr must yield an element collection, but not «exprResult»''');
						}
					} else {
						exprResult
					}

				} else if(matcher!=null){
					matcher //The matcher itself is put on value stack
				} else if(switcher!=null){
					switcher
				} else if (!propertyFilters.nullOrEmpty) {

					propertyFilters.map[getFilteredProperties(currentAnnotatedClass, currentGeneratedClass)].flatten.
						toList

				} else if (typeQuery != null) {
					evalTypeQuery(vs, typeQuery, element)
				} else {
					throw new IllegalArgumentException("Either expr or propertyFilter must be set for the variable.");

				}
				
			val valueForVariable = if(annotationToRetrieve==null){
				value
			} else {
				value.retrieveAnnotationMirrors(annotationToRetrieve.qualifiedName)
			}
			
			vs.put(name, valueForVariable)
			if (setInShadowAnnotation && !avName.nullOrEmpty) {
				//TODO: Es fürfte ungewöhnlich sein, hier einen AnnotationMirror zu setzen. Daher nehmen wir value anstatt valueForVariable.
				//Ist das sinnvoll oder eher verwirrend? 
				vs.getVariablesForShadowAnnotation().put(avName, value)
			}

		} catch (TypeElementNotFoundException tenfe) {
			ExtensionRegistry.get(TypesRegistry).handleTypeElementNotFound(tenfe, currentAnnotatedClass)
		} catch (Exception e) {
			reportError(
				'''Could not evaluate EL variable «name»: «e.message» EL expression: «expr», Property Filter: «propertyFilters».''',
				e, element, elVarAnnotation, null)
		} finally {
			popCurrentMetaAnnotation()
		}

	//TODO: handle TENFE here?
	}
	
	def private dispatch Object retrieveAnnotationMirrors(Iterable<?> iterable, String annotationFqn) {
		new ArrayList(iterable.map[retrieveAnnotationMirrors(annotationFqn)].filter[it!=null].toList) 
	}
	
	def private dispatch AnnotationMirror retrieveAnnotationMirrors(TypeMirror t, String annotationFqn) {
		t.asElement.annotationMirror(annotationFqn)
	}
	
	def private dispatch AnnotationMirror retrieveAnnotationMirrors(Element e, String annotationFqn) {
		e.annotationMirror(annotationFqn)
	}
	
	def private dispatch Object retrieveAnnotationMirrors(Object object, String annotationFqn) {
		throw new IllegalArgumentException('''Cannot retrieve annotation «annotationFqn» for «object»''')
	}
	
	

	def evalTypeQuery(ValueStack vs, AnnotationMirror typeQuery, Element element) {
		val triggerAnnotation = typeQuery.value("annotation", TypeMirror);
		val shadow = typeQuery.value("shadow", Boolean);
		val unique = typeQuery.value("unique", Boolean);
		val filterAV = typeQuery.value("filterAV", String);
		val inExpr = typeQuery.value("inExpr", String);
		val inExprLang = typeQuery.value("inExprLang", String);

		//TODO: constant
		val ac = currentAnnotatedClass

		val inTypesSet = if (filterAV.nullOrEmpty)
				emptySet
			else {
				val inTypes = vs.scope(element) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
					eval(vs, inExpr, inExprLang, Object);
				]

				(if (inTypes instanceof Iterable<?>) {
					(inTypes as Iterable<TypeMirror>).toSet
				} else {
					Collections.singleton(inTypes as TypeMirror)
				}).map[qualifiedName].toSet

			}

		val types = ExtensionRegistry.get(TypesRegistry).
			findAllTypeElementsWithTriggerAnnotation(ac, triggerAnnotation.qualifiedName, shadow).filter [ te |
				filterAV.nullOrEmpty || {
					val t = te.annotationMirror(triggerAnnotation.qualifiedName).value(filterAV, TypeMirror)
					inTypesSet.contains(t.qualifiedName)
				}
			].map[asType];

		if(unique) MoreCollectionExtensions.singleValue(types) else types

	}

}
