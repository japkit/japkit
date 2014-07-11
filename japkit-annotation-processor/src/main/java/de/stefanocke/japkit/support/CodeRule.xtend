package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.EmitterContext
import de.stefanocke.japkit.support.el.ValueStack
import java.util.List
import javax.lang.model.element.Element
import javax.lang.model.type.DeclaredType
import org.eclipse.xtext.xbase.lib.Pair
import de.stefanocke.japkit.support.el.ELSupport
import javax.lang.model.element.AnnotationMirror
import de.stefanocke.japkit.gen.GenElement

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
	
	new(AnnotationMirror metaAnnotation, String avPrefix){
		_metaAnnotation = metaAnnotation
		_bodyExpr = metaAnnotation.value('''«avPrefix»Expr''', String)
		_lang = metaAnnotation.value('''«avPrefix»Lang''', String)
		
		val bodyCaseAnnotations = metaAnnotation.value('''«avPrefix»Switch''', typeof(AnnotationMirror[])) 
		
		_bodyCases = bodyCaseAnnotations?.map[
			elementMatchers('matcher', null) 
			-> value('expr', String)
		]?.toList ?: emptyList


		_beforeExpr = metaAnnotation.value('''«avPrefix»BeforeExpr''', String)
		_afterExpr = metaAnnotation.value('''«avPrefix»AfterExpr''', String)
		_emptyExpr = metaAnnotation.value('''«avPrefix»EmptyExpr''', String)

		//body iterator
		_iteratorExpr = metaAnnotation.value('''«avPrefix»Iterator''', String)
		_iteratorLang = metaAnnotation.value('''«avPrefix»IteratorLang''', String)

		_separator = metaAnnotation.value('''«avPrefix»Separator''', String)

		_imports = metaAnnotation.value("imports", typeof(DeclaredType[]))
		
	}
	
	/**
	 * Gets the code as a closure usable in generated methods, constructors and fields.
	 */
	protected def getAsCodeBody(GenElement element) {
		if(metaAnnotation == null) return null

		//deep copy current state of value stack, since the closure is evaluated later (in JavaEmitter)
		val valueStack = new ValueStack(valueStack);
		[ EmitterContext ec |
			
			valueStack.scope(element) [ vs |
				vs.put("ec", ec)
				evalBodyExpr(ec, vs, element)
			]
		]

		
	}
	
	private def CharSequence evalBodyExpr(EmitterContext ec, ValueStack vs, Element ruleSrcElement) {
		if (bodyExpr.nullOrEmpty && bodyCases.empty) return null //Really?
		
		imports.forEach [
		if (!ec.importIfPossible(it)) {
				reportError('''Import for «it» not possible since it conflicts with existing import''',
					null, metaAnnotation, 'imports')
			}
		]
		handleTypeElementNotFound(null, '''Code body «bodyExpr» could not be generated''') [
			
			
			if (iteratorExpr.nullOrEmpty) {							
				evalBodyExpr(vs, ruleSrcElement, bodyCases, bodyExpr, lang, 'throw new UnsupportedOperationException();')
			} else {
				val bodyIterator = eval(vs, iteratorExpr, iteratorLang, Iterable,
					'''Error in code body iterator expression.''', emptyList)
				if(!bodyIterator.nullOrEmpty){	
					val before = eval(vs, beforeExpr, lang, String,
						'''Error in code body before expression.''', '')
					val after = eval(vs, afterExpr, lang, String,
						'''Error in code body after expression.''', '')
					'''
						«FOR e : bodyIterator BEFORE before SEPARATOR separator AFTER after»
							«vs.scope(e as Element) [ vsInIteration |
								evalBodyExpr(vsInIteration, e as Element, bodyCases, bodyExpr, lang, '')
							]»
						«ENDFOR»
					'''	
				} else {								
					eval(vs, emptyExpr, lang, String, '''Error in code body empty expression.''',
							'throw new UnsupportedOperationException();')
				}
			}
		]
	}
	
	private def CharSequence evalBodyExpr(ValueStack vs, Element ruleSrcElement, List<Pair<List<ElementMatcher>, String>> bodyCases, String bodyExpr, String lang, String errorResult) {
		val bodyExprToUse = bodyCases.findFirst[
			val matcher = key
			!matcher.nullOrEmpty && matcher.exists[matches(ruleSrcElement)]
		]?.value ?: bodyExpr
		
		eval(vs, bodyExprToUse, lang, String, '''Error in code body expression.''',
				errorResult)
	}}