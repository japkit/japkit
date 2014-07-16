package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import java.util.ArrayList
import java.util.Collections
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror

import static de.stefanocke.japkit.support.MemberRuleSupport.*

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

	AnnotationMirror metaAnnotation
	E template
	(Element)=>Iterable<? extends Element> srcElementsRule
	(Element)=>String nameRule
	(GenElement, Element)=>List<? extends AnnotationMirror> annotationMappingRules
	
	protected static val (Element)=>Iterable<? extends Element> SINGLE_SRC_ELEMENT = [Element e |  Collections.singleton(e)]
	
	//If there are no annoation mappings, the annotations on the generated element are the ones from the template
	protected static val NO_ANNOTATION_MAPPINGS = [GenElement gen, Element src |  gen.annotationMirrors]
	
	new(AnnotationMirror metaAnnotation, E template){
		_metaAnnotation = metaAnnotation
		_template = template		
		_srcElementsRule = metaAnnotation?.createSrcElementsRule ?: SINGLE_SRC_ELEMENT
		_nameRule = createNameRule(metaAnnotation)
		
		_annotationMappingRules = metaAnnotation?.createAnnotationMappingRules ?: NO_ANNOTATION_MAPPINGS
	}
	
	protected def (Element)=>Iterable<? extends Element> createSrcElementsRule(AnnotationMirror mirror){
		createIteratorExpressionRule(metaAnnotation)
	}
	
	protected def (Element)=>Iterable<? extends Element> createIteratorExpressionRule(AnnotationMirror metaAnnotation) {
		if(metaAnnotation==null) return SINGLE_SRC_ELEMENT
		
		val iteratorExpr = metaAnnotation.value("iterator", String)
		val iteratorLang = metaAnnotation.value("iteratorLang", String);

		[Element ruleSrcElement|
			val srcElements = if (iteratorExpr.nullOrEmpty) {
					Collections.singleton(ruleSrcElement)
				} else {
					eval(ruleSrcElement, iteratorExpr, iteratorLang, Iterable,
						'''Iterator expression «iteratorExpr» could not be evaluated''', emptyList).
						filterInstanceOf(Element)
				} 
			srcElements
		]
	}
	
	protected def (Element)=>String createNameRule(AnnotationMirror metaAnnotation) {
		createNameExprRule(metaAnnotation)
	}
	/** Gets a name from an annotation / meta annotation looking for AVs like name and nameExpr */
	protected def (Object)=>String createNameExprRule(AnnotationMirror metaAnnotation) {
		if(metaAnnotation == null) return [null]
		val name = metaAnnotation.value("name", String)
		val nameExpr = metaAnnotation.value("nameExpr", String)
		val nameLang = metaAnnotation.value("nameLang", String);

		[
			if (!nameExpr.nullOrEmpty) {
				eval(valueStack, nameExpr, nameLang, String, '''Member name could not be generated''',
					'invalidMemberName')
			} else {
				name
			}
		]
	}
	
	protected def (GenElement, Element)=>List<? extends AnnotationMirror> createAnnotationMappingRules(
		AnnotationMirror metaAnnotation) {
		if(metaAnnotation==null) return NO_ANNOTATION_MAPPINGS
		val mappings = metaAnnotation.annotationMappings("annotationMappings", null);
		[ GenElement genElement, Element ruleSrcElement |
			mapAnnotations(ruleSrcElement, mappings,
				new ArrayList(genElement.annotationMirrors.map[it as GenAnnotationMirror]))
		]
	}

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

			val srcElements = srcElementsRule.apply(ruleSrcElement) 

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
		member.annotationMirrors = annotationMappingRules.apply(member, ruleSrcElement)
		setModifiersFromMetaAnnotation(member, triggerAnnotation)
		member
	}

	/**
	 * Creates the member from the template or by calling the factory and sets the name.
	 */
	protected def <T extends GenElement> T createMember(AnnotationMirror triggerAnnotation, TypeElement annotatedClass,
		GenTypeElement generatedClass, Element ruleSrcElement, (String)=>T factory) {
		val memberName = nameRule.apply(ruleSrcElement)

		val genElement = if (template == null) {
				factory.apply(memberName)
			} else {

				//Copy member from template and transform types (for example, replace "AnnotatedClass")
				genExtensions.copyFrom(template, true,
					relatedTypesTransformation(annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement))
			}

		if (!memberName.nullOrEmpty) {

			//Override name from template, if requested
			genElement.simpleName = memberName
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
