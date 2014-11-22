package de.stefanocke.japkit.rules

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.el.ELSupport
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import org.eclipse.xtext.xbase.lib.Functions.Function1

@Data
public abstract class MemberRuleSupport<E extends Element, T extends GenElement> extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>>{
	val protected extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)

	val protected extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val protected extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val protected extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	val protected extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val protected extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val protected extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val protected RuleUtils ru = ExtensionRegistry.get(RuleUtils)


	E template
	String avPrefix
	
	()=>boolean activationRule
	((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> scopeRule
	()=>Iterable<? extends Object> srcRule
	()=>String nameRule
	()=>Set<Modifier> modifiersRule
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	()=>CharSequence commentRule
	boolean genElementIsSrcForDependentRules
	ManualOverrideRule manualOverrideRule
	
	//members to be created for the generated member. for instance, getters and setters to  be created for the generated field
	List<(GenTypeElement) => List<? extends GenElement>> dependentMemberRules = newArrayList()

	new(AnnotationMirror metaAnnotation, E template){
		this(metaAnnotation, template, null)
	}
	
	new(AnnotationMirror metaAnnotation, E template, String avPrefix){
		super(metaAnnotation, template)
		_template = template
		_avPrefix = avPrefix
		_activationRule	= createActivationRule	
		_srcRule = createSrcRule 
		_scopeRule = createScopeRule(srcRule)
		_nameRule = createNameRule
		_modifiersRule = createModifiersRule
		_annotationsRule = createAnnotationsRule
		_commentRule = createCommentRule
		_genElementIsSrcForDependentRules = genElementIsSrcForDependentRulesAV
		createAndAddDelegateMethodRules
		
		_manualOverrideRule = new ManualOverrideRule(metaAnnotation)
	}
	
	
	new(AnnotationMirror metaAnnotation, String avPrefix, ()=>Iterable<? extends Object> srcRule, ()=>String nameRule, ()=>CharSequence commentRule){
		super(metaAnnotation, null)
		_template = null
		_avPrefix = avPrefix
		_activationRule	= createActivationRule
		_srcRule =  srcRule ?: RuleUtils.SINGLE_SRC_ELEMENT 
		_scopeRule = createScopeRule(srcRule)
		_nameRule = nameRule
		_modifiersRule = createModifiersRule
		_annotationsRule = createAnnotationsRule
		_commentRule = commentRule ?: createCommentRule
		_genElementIsSrcForDependentRules = genElementIsSrcForDependentRulesAV
		createAndAddDelegateMethodRules
		_manualOverrideRule = new ManualOverrideRule(metaAnnotation)
	}
	
	new(()=>boolean activationRule,
		()=>Iterable<? extends Object> srcRule, ()=>String nameRule,
		()=>Set<Modifier> modifiersRule, (GenElement)=>List<? extends AnnotationMirror> annotationsRule, ()=>CharSequence commentRule) {
		super(null, null)
		_template = null
		_avPrefix = null
		_activationRule = activationRule ?: RuleUtils.ALWAYS_ACTIVE
		_srcRule = srcRule ?: RuleUtils.SINGLE_SRC_ELEMENT
		_scopeRule = createScopeRule(srcRule)
		_nameRule = nameRule
		_modifiersRule = modifiersRule ?: [| emptySet]
		_annotationsRule = annotationsRule ?: [g |emptyList]
		_commentRule = commentRule ?: [|""]
		_genElementIsSrcForDependentRules = true
		_manualOverrideRule = null
	}
	
	protected def genElementIsSrcForDependentRulesAV(){
		 metaAnnotation?.value("genElementIsSrcForDependentRules", Boolean) ?: true	 
	}
	
	protected def void addDependentMemberRule(MemberRuleSupport<?,?> mr){
		if(mr==null) return;
		dependentMemberRules.add [g| mr.apply(g)]
	}
	
	
	protected def ()=>boolean createActivationRule(){
		ru.createActivationRule(metaAnnotation, avPrefix)
	}	
	
	protected def ()=>Iterable<? extends Object> createSrcRule(){
		ru.createSrcExpressionRule(metaAnnotation, avPrefix)
	}
	
	protected def ((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> createScopeRule(()=>Iterable<? extends Object> srcRule){
		ru.createScopeRule(metaAnnotation, template, avPrefix, srcRule)  
	}
	
	protected def ()=>Set<Modifier> createModifiersRule(){
		ru.createModifiersRule(metaAnnotation, template, avPrefix)
	}
	
	protected def (GenElement)=>List<? extends AnnotationMirror> createAnnotationsRule(){
		ru.createAnnotationMappingRules(metaAnnotation, template, avPrefix)
	}
	
	protected def ()=>String createNameRule() {
		ru.createNameExprRule(metaAnnotation, template, avPrefix)
	}
	
	protected def ()=>CharSequence createCommentRule() {
		ru.createCommentRule(metaAnnotation, template, avPrefix, null)
	}
	

	protected def getGenExtensions() {
		ExtensionRegistry.get(GenExtensions)
	}

	override apply(GenTypeElement generatedClass) {
		inRule[
			if(!scope[
				valueStack.put("template", template)
				activationRule.apply			
			]) 
			return emptyList
	
			try{
	
				val result = scopeRule.apply [
					
					//TODO
					valueStack.put("template", template)
					val generatedMembers = newArrayList()
					val member = createMember
					generatedClass.add(member)
					generatedMembers.add(member)
					
					scope(getSrcElementForDependentRules(member))[
						//make the member just generated available on value stack
						valueStack.put("genElement", member)
						dependentMemberRules.forEach [ r |
							//apply dependent rules. 
							generatedMembers.addAll(r.apply(generatedClass))
						
						]
						null			
					]
					generatedMembers
				]
				
				manualOverrideRule?.apply(result.map[head])  
				
				result.flatten.toList
				
			} catch(Exception re) {
				//TODO: What about TENFE?
				//TODO: Should we move this to scope rule?
				
				//don't let one member rule screw up the whole class
				reportRuleError('''Error in member rule: «re»''')
				emptyList
			} 
		
		]

	}
	
	protected def getSrcElementForDependentRules(GenElement genElement){
		if (genElementIsSrcForDependentRules) genElement else currentSrcElement
	}
	
	


	/**
	 * To be overridden by subclasses to create the member.
	 */
	protected def T createMember(){
		val memberName = nameRule.apply
		val member = createMember(memberName)
		member.applyRulesAfterCreation
		member 
	}
	
	protected def T createMember(String name);


	protected def void applyRulesAfterCreation(T member) {
		member.modifiers=modifiersRule.apply
		member.annotationMirrors=annotationsRule.apply(member)
		member.comment = commentRule.apply
	}
	

	protected def void createAndAddDelegateMethodRules() {
		if(metaAnnotation == null) return;
		
		metaAnnotation.value("delegateMethods", typeof(AnnotationMirror[]))?.forEach [
			val dmr =  new DelegateMethodsRule(it, null)
			addDependentMemberRule(dmr) 
		]
		
	}
	
	
}
