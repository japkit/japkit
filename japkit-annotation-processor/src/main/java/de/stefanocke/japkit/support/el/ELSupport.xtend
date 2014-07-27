package de.stefanocke.japkit.support.el

import com.google.common.base.Stopwatch
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.TypeElementNotFoundException
import de.stefanocke.japkit.support.TypesExtensions
import java.io.Writer
import java.net.URL
import java.util.Map
import java.util.ServiceLoader
import java.util.concurrent.TimeUnit
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

import static de.stefanocke.japkit.util.MoreCollectionExtensions.*

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

	def <T> T scope(ValueStack vs, Object e, (ValueStack)=>T closure) {
		try {
			vs.push
			vs.put("src", e)
			closure.apply(vs)

		} finally {
			vs.pop
		}
	}
	
	def <T> T scope(ValueStack vs, (ValueStack)=>T closure) {
		try {
			vs.push
			closure.apply(vs)

		} finally {
			vs.pop
		}
	}

	def void scope(ValueStack vs, Object e, (ValueStack)=>void closure) {
		try {
			vs.push
			vs.put("src", e)
			closure.apply(vs)

		} finally {
			vs.pop
		}
	}
	
	def void scope(ValueStack vs, (ValueStack)=>void closure) {
		try {
			vs.push
			closure.apply(vs)

		} finally {
			vs.pop
		}
	}
	
	def getCurrentSrcElement() {
		getCurrentSrc(Element)
	}
	
	def <T> T getCurrentSrc(Class<T> clazz){
		clazz.cast(getCurrentSrc)
	}
	
	def Object getCurrentSrc(){
		valueStack.getRequired("src")
	}

	def <T> T eval(Object src, String expr, String lang, Class<T> expectedType, CharSequence errorMessage,
		T errorResult) {
		valueStack.scope(src) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
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
			reportError('''«errorMessage»: «e.message» EL expression: «expr»''', if(currentSrc instanceof Element) getCurrentSrcElement else null ,
				null, null)
			errorResult
		}
	}

	//
	def <T> T eval(Object src, String expr, String lang, Class<T> expectedType) {
		valueStack.scope(src) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
			eval(it, expr, lang, expectedType)
		]
	}

	def <T> T eval(ValueStack valueStack, String expr, String lang, Class<T> expectedType) {
		if(expr.nullOrEmpty && expectedType == String){
			return ("" as Object) as T //WTF!?!
		}

		withValueStack(valueStack)[|
			//nicht schön hier.
			putShadowAnnotation(valueStack)
			return getElProvider(lang).eval(valueStack as Map<String, Object>, expr, expectedType, lang) as T
		]
	}
	
	/**
	 * Changes the thread local value stack and restores it at the end
	 */
	def <T> T withValueStack(ValueStack valueStack, ()=>T closure) {
		var ValueStack oldValueStackTL = null
		if (valueStack != getValueStack) {
			oldValueStackTL = getValueStack

			//Make an explicitely set value stack available to EL Var functions called within the expression
			ExtensionRegistry.register(ValueStack, valueStack)
		}
		try {
			closure.apply
		} finally {

			if (oldValueStackTL != null) {
				ExtensionRegistry.register(ValueStack, oldValueStackTL)
			}

		}
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

		//TODO: Use Rule Factory
		val varRule = new ELVariableRule(elVarAnnotation)
		varRule.putELVariable(vs, element, triggerAnnotation)
	}
	


}
