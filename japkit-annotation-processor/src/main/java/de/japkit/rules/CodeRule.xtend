package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.el.ValueStack
import de.japkit.model.CodeBody
import de.japkit.model.EmitterContext
import de.japkit.model.GenElement
import de.japkit.services.ExtensionRegistry
import de.japkit.services.MessageCollector
import de.japkit.services.TypeElementNotFoundException
import java.util.List
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.DeclaredType
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend2.lib.StringConcatenation

@Data
class CodeRule extends AbstractRule implements IParameterlessFunctionRule<CharSequence> {

	val protected transient extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(
		AnnotationExtensions)

	Element template
	List<DeclaredType> imports
	String iteratorExpr
	String iteratorLang
	String bodyExpr
	List<CaseRule<String>> bodyCases
	String lang
	String beforeExpr
	String afterExpr
	String separator
	String emptyExpr
	String errorValue
	(CharSequence)=>CharSequence defaultFragmentsRule
	boolean linebreak
	boolean indentAfterLinebreak
	
	val LINE_DELIM = StringConcatenation.DEFAULT_LINE_DELIMITER;

	new(AnnotationMirror metaAnnotation, String avPrefix) {
		this(metaAnnotation, null, avPrefix, "")
	}

	new(AnnotationMirror metaAnnotation, Element template, String avPrefix, String errorValue) {
		super(metaAnnotation, template)
		this.template = template

		val codeFromJavadoc = JavadocUtil.getCode(template?.getDocCommentUsingRuntimeMetadata)

		bodyExpr = stringFromAnnotationOrMap(metaAnnotation, codeFromJavadoc, "code".withPrefix(avPrefix))

		lang = metaAnnotation?.value("lang".withPrefix(avPrefix), String)

		val bodyCaseAnnotations = metaAnnotation?.value("cases".withPrefix(avPrefix), typeof(AnnotationMirror[]))

		bodyCases = bodyCaseAnnotations?.map[new CaseRule(it, null, String, false)]?.toList ?: emptyList

		beforeExpr = stringFromAnnotationOrMap(metaAnnotation, codeFromJavadoc,
			"beforeIteratorCode".withPrefix(avPrefix))
		afterExpr = stringFromAnnotationOrMap(metaAnnotation, codeFromJavadoc, "afterIteratorCode".withPrefix(avPrefix))
		emptyExpr = stringFromAnnotationOrMap(metaAnnotation, codeFromJavadoc, "emptyIteratorCode".withPrefix(avPrefix))
		separator = stringFromAnnotationOrMap(metaAnnotation, codeFromJavadoc, "separator".withPrefix(avPrefix))

		this.errorValue = errorValue;

		// body iterator
		iteratorExpr = metaAnnotation?.value("iterator".withPrefix(avPrefix), String)
		iteratorLang = metaAnnotation?.value("iteratorLang".withPrefix(avPrefix), String)

		imports = metaAnnotation?.value("imports", typeof(DeclaredType[]))?.toList ?: emptyList

		linebreak = metaAnnotation?.value("linebreak".withPrefix(avPrefix), boolean) ?: false
		indentAfterLinebreak = metaAnnotation?.value("indentAfterLinebreak".withPrefix(avPrefix), boolean) ?: false

		defaultFragmentsRule = CodeFragmentRules.createDefaultFragmentsRule(metaAnnotation, avPrefix)
	}

	private def stringFromAnnotationOrMap(AnnotationMirror metaAnnotation, Map<String, String> map, String name) {
		val av = metaAnnotation?.value(name, String)
		(if(av.nullOrEmpty) map?.get(name) else av) ?: ""
	}

	private static def withPrefix(String name, String prefix) {
		if(prefix.nullOrEmpty) name else '''«prefix»«name.toFirstUpper»'''.toString
	}

	/**
	 * Gets the code as a closure usable in generated methods, constructors and fields.
	 */
	def static CodeBody getAsCodeBody(GenElement genElement, CodeRule cr) {
		if(cr === null) return null

		val extension ELSupport = ExtensionRegistry.get(ELSupport)

		// deep copy current state of value stack, since the closure is evaluated later (in JavaEmitter)
		val vs = new ValueStack(valueStack);
		[ EmitterContext ec |
			withValueStack(vs) [|
				scope [
					it.put("ec", ec)
					it.put("genElement", genElement)
					cr.code
				]
			]
		]

	}

	def static CodeBody getAsCodeBody(GenElement genElement, (GenElement)=>CharSequence cr,
		(CharSequence)=>CharSequence defaultFragments) {
		val extension ELSupport = ExtensionRegistry.get(ELSupport)

		// deep copy current state of value stack, since the closure is evaluated later (in JavaEmitter)
		val vs = new ValueStack(valueStack);
		[ EmitterContext ec |

			withValueStack(vs) [|
				scope [
					try {
						it.put("ec", ec)
						it.put("genElement", genElement)
						val result = cr.apply(genElement)
						defaultFragments?.apply(result) ?: result

					} catch (TypeElementNotFoundException e) {
						throw e
					} catch (Exception e) {
						ExtensionRegistry.get(MessageCollector).reportRuleError(e.message);
						''''''
					}
				]
			]
		]

	}

	def static (GenElement)=>CodeBody createCodeBodyRule((GenElement)=>CharSequence codeRule,
		(CharSequence)=>CharSequence defaultFragments) {
		[ genElement |
			CodeRule.getAsCodeBody(genElement, codeRule, defaultFragments)
		]
	}

	/**
	 * Gets the code as CharSequence. The EmitterContext an the context element must be available on the thread local value stack.
	 * This method is aimed to be used to include reusable code fragments into other code expressions.
	 */
	def code() {
		code(valueStack.getRequired("ec") as EmitterContext)
	}

	private def CharSequence code(EmitterContext ec) {

		inRule[
			handleException([|errorValue], null) [
				if(bodyExpr.nullOrEmpty && bodyCases.empty) return null // Really?
				imports.forEach [
					if (!ec.importIfPossible(it)) {
						reportRuleError('''Import for «it» not possible since it conflicts with existing import''',
							'imports')
					}
				]
				handleTypeElementNotFound(null, errorValue) [
					val result = if (iteratorExpr.nullOrEmpty) {
							code(bodyCases, bodyExpr, lang, errorValue)
						} else {
							val bodyIterator = eval(iteratorExpr, iteratorLang,
								Iterable, '''Error in code body iterator expression.''', emptyList)
							if (!bodyIterator.nullOrEmpty) {
								val before = eval(beforeExpr, lang,
									CharSequence, '''Error in code body before expression.''', '').
									withLinebreak(linebreak) + if(linebreak && indentAfterLinebreak) '\t' else ''
								
								//If there shall be linebreak, it is also added after the last iteration (== before the 'after'-code)
								//However, if the iterated code is indented, we assume that the 'after'-code shall be kept on same line 
								val after =
									(if(linebreak && !indentAfterLinebreak) LINE_DELIM else '') + 
									eval(afterExpr, lang,
										CharSequence, '''Error in code body after expression.''', '').withLinebreak(linebreak)
								val sep = separator + if(linebreak) LINE_DELIM + (if(indentAfterLinebreak)'\t' else '') else '';
								'''«FOR e : bodyIterator BEFORE before SEPARATOR sep AFTER after»«scope(e as Element) [code(bodyCases, bodyExpr, lang, '')]»«ENDFOR»'''
							} else {
								eval(emptyExpr, lang, CharSequence, '''Error in code body empty expression.''',
									errorValue)
							}
						}

					try{
						defaultFragmentsRule.apply(result)					
					} catch(Exception e) {
						reportRuleError(e)
						result
					}

				]
			]
		]

	}

	private def CharSequence code(List<CaseRule<String>> bodyCases, String bodyExpr, String lang, String errorResult) {
		CaseRule.findFirstMatching(bodyCases)?.apply ?:
			eval(bodyExpr, lang, CharSequence, "Error in code body expression.", errorResult)
	// TODO: ErrorResult bei den Cases??
	}

	static def CharSequence withLinebreak(CharSequence cs) {
		withLinebreak(cs, true)
	}

	static def CharSequence withLinebreak(CharSequence cs, boolean linebreak) {
		if (linebreak && cs !== null && cs.length > 0) '''«cs»
		''' else
			cs
	}

	override apply() {
		code()
	}

	override apply(Object p) {
		scope(p) [
			code()
		]
	}

}
