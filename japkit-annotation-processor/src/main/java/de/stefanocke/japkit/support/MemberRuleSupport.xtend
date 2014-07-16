package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import java.util.Set

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
	val protected RuleUtils ru = ExtensionRegistry.get(RuleUtils)

	AnnotationMirror metaAnnotation
	E template
	(Element)=>Iterable<? extends Element> srcElementsRule
	(Element)=>String nameRule
	(Element)=>Set<Modifier> modifiersRule
	(GenElement, Element)=>List<? extends AnnotationMirror> annotationMappingRules
	
	new(AnnotationMirror metaAnnotation, E template){
		_metaAnnotation = metaAnnotation
		_template = template		
		_srcElementsRule = createSrcElementsRule 
		_nameRule = createNameRule
		_modifiersRule = createModifiersRule
		_annotationMappingRules = createAnnotationMappingRules
	}
	
	protected def (Element)=>Set<Modifier> createModifiersRule(){
		ru.createModifiersRule(metaAnnotation, template)
	}
	
	protected def (GenElement, Element)=>List<? extends AnnotationMirror> createAnnotationMappingRules(){
		ru.createAnnotationMappingRules(metaAnnotation)
	}
	
	protected def (Element)=>Iterable<? extends Element> createSrcElementsRule(){
		ru.createIteratorExpressionRule(metaAnnotation)
	}
	
	
	protected def (Element)=>String createNameRule() {
		ru.createNameExprRule(metaAnnotation, template)
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
		member.modifiers = modifiersRule.apply(ruleSrcElement)
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
