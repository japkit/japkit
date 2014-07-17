package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement

import static extension de.stefanocke.japkit.support.RuleUtils.*

@Data
public abstract class MemberRuleSupport<E extends Element, T extends GenElement> {
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
	
	(Element)=>boolean activationRule
	(Element)=>Iterable<? extends Element> srcElementsRule
	(Element)=>String nameRule
	
	private List<(T, Element)=>void> afterCreationRules = newArrayList()
	
	
	new(AnnotationMirror metaAnnotation, E template){
		_metaAnnotation = metaAnnotation
		_template = template
		_activationRule	= createActivationRule
		_srcElementsRule = createSrcElementsRule 
		_nameRule = createNameRule
		addAfterCreationRule(createModifiersRule) [e, m | e.modifiers = m]
		addAfterCreationRule(createAnnotationMappingRules) [e, a | e.annotationMirrors = a]
	}
	
	protected def <R> addAfterCreationRule((Element)=>R rule, (T, R)=>void setter){
		afterCreationRules.add(rule.andAssignResult(setter))
	}
	
	protected def (Element)=>boolean createActivationRule(){
		ru.createActivationRule(metaAnnotation)
	}	
	
	protected def (Element)=>Iterable<? extends Element> createSrcElementsRule(){
		ru.createIteratorExpressionRule(metaAnnotation)
	}
	
	protected def (Element)=>Set<Modifier> createModifiersRule(){
		ru.createModifiersRule(metaAnnotation, template)
	}
	
	protected def (Element)=>List<? extends AnnotationMirror> createAnnotationMappingRules(){
		ru.createAnnotationMappingRules(metaAnnotation, template)
	}
	
	protected def (Element)=>String createNameRule() {
		ru.createNameExprRule(metaAnnotation, template)
	}
	

	protected def getGenExtensions() {
		ExtensionRegistry.get(GenExtensions)
	}

	def void apply(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation,
		Element ruleSrcElement) {

		if (!activationRule.apply(ruleSrcElement)) {
			return
		}

		try {
			pushCurrentMetaAnnotation(metaAnnotation)

			val srcElements = srcElementsRule.apply(ruleSrcElement) 

			srcElements.forEach [ e |
				valueStack.scope(e) [
					valueStack.putELVariables(e, triggerAnnotation, metaAnnotation)
					val member = createMember(e)
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
	protected def GenElement createMember(Element ruleSrcElement);

	/**
	 * Creates the member from the template or by calling the factory and sets the name, the modifiers and the annotations.
	 */
	protected def T createMemberAndSetCommonAttributes(Element ruleSrcElement, (String)=>T factory) {
		val member = createMember(ruleSrcElement, factory)
		afterCreationRules.forEach[apply(member, ruleSrcElement)]
		member
	}

	/**
	 * Creates the member from the template or by calling the factory and sets the name.
	 */
	protected def <T extends GenElement> T createMember(Element ruleSrcElement, (String)=>T factory) {
		val memberName = nameRule.apply(ruleSrcElement)
		factory.apply(memberName)			
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
