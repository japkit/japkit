package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.EmitterContext
import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ValueStack
import java.util.ArrayList
import java.util.Collections
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import org.eclipse.xtext.xbase.lib.Pair

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

@Data
public abstract class MemberRuleSupport<E extends Element> {
	val protected extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)

	//val extension RoundEnvironment roundEnv = ExtensionRegistry.get(RoundEnvironment)
	val protected extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val protected extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val protected extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	val protected extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val protected extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val protected extension RelatedTypes relatedTypes = ExtensionRegistry.get(RelatedTypes)

	protected AnnotationMirror metaAnnotation
	protected E template

	protected def getGenExtensions() {
		ExtensionRegistry.get(GenExtensions)
	}

	def void apply(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation,
		Element ruleSrcElement) {

		if (!isActive(triggerAnnotation, ruleSrcElement)) {
			return
		}

		try {
			pushCurrentMetaAnnotation(metaAnnotation)

			val srcElements = getSrcElements(triggerAnnotation, ruleSrcElement)

			srcElements.forEach [ e |
				valueStack.scope(e) [
					valueStack.putELVariables(e, triggerAnnotation, metaAnnotation)
					val member = createMember(annotatedClass, generatedClass, triggerAnnotation, e)
					generatedClass.add(member)
					//Create delegate methods that use the generated member to retrieve the object to delegate to
					createDelegateMethods(member, annotatedClass, generatedClass, triggerAnnotation)
				]
			]
		} catch(Exception re) {
			//don't let one member screw up the whole class
			reportError('''Error in meta annotation «metaAnnotation» «IF template !=null»in template «template» «ENDIF»''', 
				re, annotatedClass, triggerAnnotation, null
			)
		} finally {
			popCurrentMetaAnnotation
		}

	}

	protected def Iterable<? extends Element> getSrcElements(AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		val iteratorExpr = triggerAnnotation.valueOrMetaValue("iterator", String, metaAnnotation)
		val iteratorLang = triggerAnnotation.valueOrMetaValue("iteratorLang", String, metaAnnotation)

		val srcElements = if (iteratorExpr.nullOrEmpty) {
				Collections.singleton(ruleSrcElement)
			} else {
				eval(ruleSrcElement, iteratorExpr, iteratorLang, Iterable,
					'''Iterator expression «iteratorExpr» could not be evaluated''', emptyList).filterInstanceOf(Element)
			}
		srcElements
	}

	/**
	 * To be overridden by subclasses to create the member.
	 */
	protected def GenElement createMember(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement);

	/**
	 * Creates the member from the template or by calling the factory and sets the name, the modifiers and the annotations.
	 */
	protected def <T extends GenElement> T createMemberAndSetCommonAttributes(AnnotationMirror triggerAnnotation,
		TypeElement annotatedClass, GenTypeElement generatedClass, Element ruleSrcElement, (String)=>T factory) {
		val member = createMember(triggerAnnotation, annotatedClass, generatedClass, ruleSrcElement, factory)
		mapAnnotations(member, triggerAnnotation, ruleSrcElement)
		setModifiersFromMetaAnnotation(member, triggerAnnotation)
		member
	}

	/**
	 * Creates the member from the template or by calling the factory and sets the name.
	 */
	protected def <T extends GenElement> T createMember(AnnotationMirror triggerAnnotation, TypeElement annotatedClass,
		GenTypeElement generatedClass, Element ruleSrcElement, (String)=>T factory) {
		val methodName = getNameFromMetaAnnotation(triggerAnnotation, ruleSrcElement)

		val genElement = if (template == null) {
				factory.apply(methodName)
			} else {

				//Copy method from template and transform types (for example, replace "AnnotatedClass")
				genExtensions.copyFrom(template, true,
					relatedTypesTransformation(annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement))
			}

		if (!methodName.nullOrEmpty) {

			//Override name from template, if requested
			genElement.simpleName = methodName
		}
		genElement as T
	}

	protected def TypeMirror typeFromMetaAnnotationOrTemplate(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, String typeAvName, String typeArgsAvName, Element ruleSrcElement,
		TypeMirror typeFromTemplate) {
		if(metaAnnotation == null) return typeFromTemplate
		val type = triggerAnnotation.resolveType(annotatedClass, generatedClass, metaAnnotation, typeAvName,
			typeArgsAvName, ruleSrcElement)
		if (!type.isVoid) {
			type
		} else {
			typeFromTemplate
		}
	}

	protected def String getNameFromMetaAnnotation(AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		if(metaAnnotation == null) return null
		val name = triggerAnnotation.valueOrMetaValue("name", String, metaAnnotation)
		val nameExpr = triggerAnnotation.valueOrMetaValue("nameExpr", String, metaAnnotation)
		val nameLang = triggerAnnotation.valueOrMetaValue("nameLang", String, metaAnnotation)
		if (!nameExpr.nullOrEmpty) {
			eval(valueStack, nameExpr, nameLang, String, '''Method name could not be generated''',
				'invalidMethodName')
		} else {
			name
		}
	}

	protected def void mapAnnotations(GenElement element, AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		if(metaAnnotation == null) return
		val annotationMappings = triggerAnnotation.annotationMappings("annotationMappings", metaAnnotation)
		element.annotationMirrors = mapAnnotations(ruleSrcElement, annotationMappings,
			new ArrayList(element.annotationMirrors.map[it as GenAnnotationMirror]))
	}

	protected def void setModifiersFromMetaAnnotation(GenElement element, AnnotationMirror triggerAnnotation) {
		if(metaAnnotation == null) return
		val modi = triggerAnnotation.valueOrMetaValue("modifiers", typeof(Modifier[]), metaAnnotation)
		if (!modi.nullOrEmpty) {
			element.modifiers = modi.toSet
		}
	}

	protected def boolean isActive(AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		if(metaAnnotation == null) return true
		val activation = triggerAnnotation.elementMatchers("activation", metaAnnotation)
		val active = activation.nullOrEmpty || activation.exists[matches(ruleSrcElement)]
		active
	}

//"initExpr", "initLang", "initIterator", "initIteratorLang", "initSeparator", "initBeforeExpr", "initAfterExpr", "initEmptyExpr"
//"bodyExpr", "bodyLang", "bodyIterator", "bodyIteratorLang", "bodySeparator", "bodyBeforeExpr", "bodyAfterExpr", "bodyEmptyExpr"
	protected def getCodeBodyFromMetaAnnotation(GenElement element, AnnotationMirror triggerAnnotation, String avPrefix) {
		if(metaAnnotation == null) return null

		//the body expression
		val bodyExpr = triggerAnnotation.valueOrMetaValue('''«avPrefix»Expr''', String, metaAnnotation)
		val lang = triggerAnnotation.valueOrMetaValue('''«avPrefix»Lang''', String, metaAnnotation)
		
		val bodyExprSwitch = (1..10).map[triggerAnnotation.elementMatchers('''«avPrefix»Case«it»''', metaAnnotation) 
			-> triggerAnnotation.valueOrMetaValue('''«avPrefix»Expr«it»''', String, metaAnnotation)
		].toList


		val beforeExpr = triggerAnnotation.valueOrMetaValue('''«avPrefix»BeforeExpr''', String, metaAnnotation)
		val afterExpr = triggerAnnotation.valueOrMetaValue('''«avPrefix»AfterExpr''', String, metaAnnotation)
		val emptyExpr = triggerAnnotation.valueOrMetaValue('''«avPrefix»EmptyExpr''', String, metaAnnotation)

		//body iterator
		val iteratorExpr = triggerAnnotation.valueOrMetaValue('''«avPrefix»Iterator''', String, metaAnnotation)
		val iteratorLang = triggerAnnotation.valueOrMetaValue('''«avPrefix»IteratorLang''', String, metaAnnotation)

		val separator = triggerAnnotation.valueOrMetaValue('''«avPrefix»Separator''', String, metaAnnotation)

		val imports = triggerAnnotation.valueOrMetaValue("imports", typeof(DeclaredType[]), metaAnnotation)
		getCodeBodyFromMetaAnnotation(element, triggerAnnotation, bodyExpr, bodyExprSwitch, 
			lang, beforeExpr, afterExpr, emptyExpr, iteratorExpr,
			iteratorLang, separator, imports)
	}

	protected def getCodeBodyFromMetaAnnotation(Element enclosingElement, AnnotationMirror triggerAnnotation,
		String bodyExpr, List<Pair<List<ElementMatcher>, String>> bodyExprSwitch, 
		String lang, String beforeExpr, String afterExpr, String emptyExpr, String iteratorExpr, String iteratorLang,
		String separator, DeclaredType[] imports) {

		if (bodyExpr.nullOrEmpty)
			null
		else {

			//deep copy current state of value stack, since body is evaluated later (in JavaEmitter)
			val valueStack = new ValueStack(valueStack);
			[ EmitterContext ec |
				imports.forEach [
					if (!ec.importIfPossible(it)) {
						reportError('''Import for «it» not possible since it conflicts with existing import''',
							enclosingElement, metaAnnotation, 'imports')
					}
				]
				valueStack.scope(enclosingElement) [ vs |
					vs.put("ec", ec)
					handleTypeElementNotFound(null, '''Code body «bodyExpr» could not be generated''') [
						
						
						if (iteratorExpr.nullOrEmpty) {							
							evalBodyExpr(vs, enclosingElement, bodyExprSwitch, bodyExpr, lang, 'throw new UnsupportedOperationException();')
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
										«valueStack.scope(e as Element) [ vsInIteration |
											evalBodyExpr(vsInIteration, e as Element, bodyExprSwitch, bodyExpr, lang, '')
										]»
									«ENDFOR»
								'''	
							} else {								
								eval(vs, emptyExpr, lang, String, '''Error in code body empty expression.''',
										'throw new UnsupportedOperationException();')
							}
						}
					]
				]
			]

		}
	}
	
	protected def evalBodyExpr(ValueStack vs, Element ruleSrcElement, List<Pair<List<ElementMatcher>, String>> bodyExprSwitch, String bodyExpr, String lang, String errorResult) {
		val bodyExprToUse = bodyExprSwitch.findFirst[
			val matcher = key
			!matcher.nullOrEmpty && matcher.exists[matches(ruleSrcElement)]
		]?.value ?: bodyExpr
		
		eval(vs, bodyExprToUse, lang, String, '''Error in code body expression.''',
				errorResult)
	}

	protected def void createDelegateMethods(GenElement genElement, TypeElement annotatedClass,
		GenTypeElement generatedClass, AnnotationMirror triggerAnnotation) {
		if(metaAnnotation == null) return
		val delegateMethodRules = triggerAnnotation.valueOrMetaValue("delegateMethods", typeof(AnnotationMirror[]),
			metaAnnotation)?.map [
			new DelegateMethodsRule(it, null)
		]
		delegateMethodRules?.forEach[apply(annotatedClass, generatedClass, triggerAnnotation, genElement)]
	}
}
