package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.EmitterContext
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ValueStack
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.DeclaredType
import org.eclipse.xtext.xbase.lib.Pair
import java.util.regex.Pattern

@Data
class CodeRule {
	val protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val protected extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val protected extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val protected extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	val protected extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val protected extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	
	AnnotationMirror metaAnnotation
	Element template
	DeclaredType[] imports
	String iteratorExpr
	String iteratorLang
	String bodyExpr
	List<Pair<List<ElementMatcher>, String>> bodyCases
	String lang
	String beforeExpr
	String afterExpr
	String separator
	String emptyExpr
	(CharSequence)=>CharSequence defaultFragmentsRule
	
	
	new(AnnotationMirror metaAnnotation, String avPrefix){
		this(metaAnnotation, null, avPrefix)
	}
	
	new(AnnotationMirror metaAnnotation, Element template, String avPrefix){
		_metaAnnotation = metaAnnotation
		_template=template
		
		val bodyExprFromAV = metaAnnotation.value("expr".withPrefix(avPrefix), String)
		_bodyExpr=if(bodyExprFromAV.nullOrEmpty) JavadocUtil.getCode(template?.getDocComment).get("expr".withPrefix(avPrefix)) else   bodyExprFromAV
		
		_lang = metaAnnotation.value("lang".withPrefix(avPrefix), String)
		
		val bodyCaseAnnotations = metaAnnotation.value("cases".withPrefix(avPrefix), typeof(AnnotationMirror[])) 
		
		_bodyCases = bodyCaseAnnotations.map[
			elementMatchers('matcher', null) 
			-> value('expr', String)
		]?.toList ?: emptyList


		_beforeExpr = metaAnnotation.value("beforeExpr".withPrefix(avPrefix), String)
		_afterExpr = metaAnnotation.value("afterExpr".withPrefix(avPrefix), String)
		_emptyExpr = metaAnnotation.value("emptyExpr".withPrefix(avPrefix), String)

		//body iterator
		_iteratorExpr = metaAnnotation.value("iterator".withPrefix(avPrefix), String)
		_iteratorLang = metaAnnotation.value("iteratorLang".withPrefix(avPrefix), String)

		_separator = metaAnnotation.value("separator".withPrefix(avPrefix), String)

		_imports = metaAnnotation.value("imports", typeof(DeclaredType[]))
		
 
		_defaultFragmentsRule = CodeFragmentRules.createDefaultFragmentsRule(metaAnnotation, avPrefix)
	}
	
	private static def withPrefix(String name, String prefix){
		if(prefix.nullOrEmpty) name else '''«prefix»«name.toFirstUpper»'''.toString
	}
	
	
	/**
	 * Gets the code as a closure usable in generated methods, constructors and fields.
	 */
	def static CodeBody getAsCodeBody(GenElement genElement, CodeRule cr) {
		if(cr == null) return null
		
		val extension ELSupport = ExtensionRegistry.get(ELSupport)

		//deep copy current state of value stack, since the closure is evaluated later (in JavaEmitter)
		val vs = new ValueStack(valueStack);
		[ EmitterContext ec |
			withValueStack(vs) [ |
				scope [
					it.put("ec", ec)
					it.put("genElement", genElement)
					cr.code
				]
			]
		]
		
	}
	
	def static CodeBody getAsCodeBody(GenElement genElement, (GenElement)=>CharSequence cr, (CharSequence)=>CharSequence defaultFragments) {
		val extension ELSupport = ExtensionRegistry.get(ELSupport)

		//deep copy current state of value stack, since the closure is evaluated later (in JavaEmitter)
		val vs = new ValueStack(valueStack);
		[ EmitterContext ec |
			
			withValueStack(vs)[|
				scope [
					it.put("ec", ec)
					it.put("genElement", genElement)
					val result = cr.apply(genElement)
					defaultFragments?.apply(result) ?: result
				]		
			]
		]

		
	}
	
	def static (GenElement)=>CodeBody createCodeBodyRule((GenElement)=>CharSequence codeRule, (CharSequence)=>CharSequence defaultFragments){
		[genElement| 
			CodeRule.getAsCodeBody(genElement, codeRule as (GenElement)=>CharSequence, defaultFragments)
		]
	}

	
	/**
	 * Gets the code as CharSequence. The EmitterContext an the context element must be available on the thread local value stack.
	 * This method is aimed to be used to include reusable code fragments into other code expressions.
	 */
	public def code(){	
		code(valueStack.getRequired("ec") as EmitterContext)
	}
	
	public def CharSequence code(EmitterContext ec) {
		if(bodyExpr.nullOrEmpty && bodyCases.empty) return null //Really?

		imports.forEach [
			if (!ec.importIfPossible(it)) {
				reportError('''Import for «it» not possible since it conflicts with existing import''', null,
					metaAnnotation, 'imports')
			}
		]
		handleTypeElementNotFound(null, '''Code body «bodyExpr» could not be generated''') [
			val result = if (iteratorExpr.nullOrEmpty) {
					code(bodyCases, bodyExpr, lang, 'throw new UnsupportedOperationException();')
				} else {
					val bodyIterator = eval(iteratorExpr, iteratorLang, Iterable,
						'''Error in code body iterator expression.''', emptyList)
					if (!bodyIterator.nullOrEmpty) {
						val before = eval(beforeExpr, lang, String,
							'''Error in code body before expression.''', '')
						val after = eval(afterExpr, lang, String,
							'''Error in code body after expression.''', '')
						'''
							«FOR e : bodyIterator BEFORE before SEPARATOR separator AFTER after»
								«scope(e as Element) [
								code(bodyCases, bodyExpr, lang, '')
							]»
							«ENDFOR»
						'''
					} else {
						eval(emptyExpr, lang, String, '''Error in code body empty expression.''',
							'throw new UnsupportedOperationException();')
					}
				}
			
			defaultFragmentsRule.apply(result)
			
		]
	}
	
	
	private def CharSequence code(List<Pair<List<ElementMatcher>, String>> bodyCases, String bodyExpr, String lang, String errorResult) {
		val bodyExprToUse = bodyCases.findFirst[
			val matcher = key
			!matcher.nullOrEmpty && matcher.exists[matches(currentSrcElement)]
		]?.value ?: bodyExpr
		
		//TODO: remove valuestack parameter
		eval(bodyExprToUse, lang, String, '''Error in code body expression.''',	errorResult)
	}}