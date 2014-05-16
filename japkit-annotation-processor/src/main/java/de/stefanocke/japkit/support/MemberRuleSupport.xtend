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
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror

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
				valueStack.scope(e)	[	
					valueStack.putELVariables(e, triggerAnnotation, metaAnnotation)		
					val member = createMember(annotatedClass, generatedClass, triggerAnnotation, e)
					generatedClass.add(member)				
				]
			]

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

	protected def getCodeBodyFromMetaAnnotation(GenElement element, AnnotationMirror triggerAnnotation, String avName,
		String langAvName) {
		if(metaAnnotation == null) return null
		val bodyExpr = triggerAnnotation.valueOrMetaValue(avName, String, metaAnnotation)

		//The language used for the expression
		val lang = triggerAnnotation.valueOrMetaValue(langAvName, String, metaAnnotation)
		val imports = triggerAnnotation.valueOrMetaValue("imports", typeof(DeclaredType[]), metaAnnotation)
		getCodeBodyFromMetaAnnotation(element, triggerAnnotation, bodyExpr, lang, imports)
	}

	protected def getCodeBodyFromMetaAnnotation(Element enclosingElement, AnnotationMirror triggerAnnotation,
		String bodyExpr, String lang, DeclaredType[] imports) {

		if (bodyExpr.nullOrEmpty)
			null
		else {
			val valueStack = new ValueStack(valueStack); //deep copy current state of value stack
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
						eval(vs, bodyExpr, lang, String, '''Code body could not be generated''',
							'throw new UnsupportedOperationException();')
					]
				]
			]

		}
	}
}
