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
	String avPrefix
	
	(Element)=>boolean activationRule
	(Element)=>Iterable<? extends Element> srcElementsRule
	(Element)=>String nameRule
	(Element)=>Set<Modifier> modifiersRule
	(Element)=>List<? extends AnnotationMirror> annotationsRule
	
	//members to be created for the generated member. for instance, getters and setters to  be created for the generated field
	List<(GenTypeElement, Element ) => void> dependentMemberRules = newArrayList()

	new(AnnotationMirror metaAnnotation, E template){
		this(metaAnnotation, template, null)
	}
	
	new(AnnotationMirror metaAnnotation, E template, String avPrefix){
		_metaAnnotation = metaAnnotation
		_template = template
		_avPrefix = avPrefix
		_activationRule	= createActivationRule
		_srcElementsRule = createSrcElementsRule 
		_nameRule = createNameRule
		_modifiersRule = createModifiersRule
		_annotationsRule = createAnnotationsRule
		createAndAddDelegateMethodRules
	}
	
	new((Element)=>boolean activationRule,
		(Element)=>Iterable<? extends Element> srcElementsRule, (Element)=>String nameRule,
		(Element)=>Set<Modifier> modifiersRule, (Element)=>List<? extends AnnotationMirror> annotationsRule) {
		_metaAnnotation = null
		_template = null
		_avPrefix = null
		_activationRule = activationRule ?: RuleUtils.ALWAYS_ACTIVE
		_srcElementsRule = srcElementsRule ?: RuleUtils.SINGLE_SRC_ELEMENT
		_nameRule = nameRule
		_modifiersRule = modifiersRule ?: [emptySet]
		_annotationsRule = annotationsRule ?: [emptyList]
	}
	
	
	protected def (Element)=>boolean createActivationRule(){
		ru.createActivationRule(metaAnnotation, avPrefix)
	}	
	
	protected def (Element)=>Iterable<? extends Element> createSrcElementsRule(){
		ru.createIteratorExpressionRule(metaAnnotation, avPrefix)
	}
	
	protected def (Element)=>Set<Modifier> createModifiersRule(){
		ru.createModifiersRule(metaAnnotation, template, avPrefix)
	}
	
	protected def (Element)=>List<? extends AnnotationMirror> createAnnotationsRule(){
		ru.createAnnotationMappingRules(metaAnnotation, template, avPrefix)
	}
	
	protected def (Element)=>String createNameRule() {
		ru.createNameExprRule(metaAnnotation, template, avPrefix)
	}
	

	protected def getGenExtensions() {
		ExtensionRegistry.get(GenExtensions)
	}

	def void apply(GenTypeElement generatedClass, Element ruleSrcElement) {

		if (!activationRule.apply(ruleSrcElement)) {
			return
		}

		try {
			pushCurrentMetaAnnotation(metaAnnotation)

			val srcElements = srcElementsRule.apply(ruleSrcElement) 

			srcElements.forEach [ e |
				valueStack.scope(e) [
					putELVariables(valueStack, e, currentAnnotation, metaAnnotation) //TODO: refactoring. use thread local context there
					val member = createMember(e)
					generatedClass.add(member)
					dependentMemberRules.forEach[r | 
						//apply dependent rules. The rule source element is the member just created.
						r.apply(generatedClass, member)
					]
				]
			]
		} catch(Exception re) {
			//don't let one member screw up the whole class
			reportError('''Error in meta annotation «metaAnnotation» «IF template !=null»in template «template» «ENDIF»''', 
				re, currentAnnotatedClass, currentAnnotation, null
			)
		} finally {
			popCurrentMetaAnnotation
		}

	}


	/**
	 * To be overridden by subclasses to create the member.
	 */
	protected def T createMember(Element ruleSrcElement){
		val memberName = nameRule.apply(ruleSrcElement)
		val member = createMember(ruleSrcElement, memberName)
		member.applyRulesAfterCreation(ruleSrcElement)
		member 
	}
	
	protected def T createMember(Element ruleSrcElement, String name);


	protected def void applyRulesAfterCreation(T member, Element ruleSrcElement) {
		member.modifiers=modifiersRule.apply(ruleSrcElement)
		member.annotationMirrors=annotationsRule.apply(ruleSrcElement)
	}
	

	protected def void createAndAddDelegateMethodRules() {
		if(metaAnnotation == null) return;
		
		metaAnnotation.value("delegateMethods", typeof(AnnotationMirror[]))?.map [
			val dmr =  new DelegateMethodsRule(it, null)
			dependentMemberRules.add [g, e| dmr.apply(g,e)] 
		]
		
	}
}
