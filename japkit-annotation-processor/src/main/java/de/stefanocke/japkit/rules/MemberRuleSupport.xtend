package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.GenElement
import de.stefanocke.japkit.model.GenExtensions
import de.stefanocke.japkit.model.GenTypeElement
import de.stefanocke.japkit.services.ExtensionRegistry
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function1
import de.stefanocke.japkit.services.TypeElementNotFoundException

@Data
public abstract class MemberRuleSupport<E extends Element, T extends GenElement> extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>>{

	E template
	String avPrefix
	
	()=>boolean activationRule
	((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> scopeRule
	()=>Object srcRule
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
		this.template = template
		this.avPrefix = avPrefix
		activationRule	= createActivationRule	
		srcRule = createSrcRule 
		scopeRule = createScopeRule(srcRule)
		nameRule = createNameRule
		modifiersRule = createModifiersRule
		annotationsRule = createAnnotationsRule
		commentRule = createCommentRule
		genElementIsSrcForDependentRules = genElementIsSrcForDependentRulesAV
		createAndAddDelegateMethodRules
		
		manualOverrideRule = new ManualOverrideRule(metaAnnotation)
	}
	
	
	new(AnnotationMirror metaAnnotation, String avPrefix, ()=>Iterable<? extends Object> srcRule, ()=>String nameRule, ()=>CharSequence commentRule){
		super(metaAnnotation, null)
		this.template = null
		this.avPrefix = avPrefix
		activationRule	= createActivationRule
		this.srcRule =  srcRule ?: RuleUtils.SINGLE_SRC_ELEMENT 
		scopeRule = createScopeRule(srcRule)
		this.nameRule = nameRule
		modifiersRule = createModifiersRule
		annotationsRule = createAnnotationsRule
		this.commentRule = commentRule ?: createCommentRule
		genElementIsSrcForDependentRules = genElementIsSrcForDependentRulesAV
		createAndAddDelegateMethodRules
		manualOverrideRule = new ManualOverrideRule(metaAnnotation)
	}
	
	new(()=>boolean activationRule,
		()=>Iterable<? extends Object> srcRule, ()=>String nameRule,
		()=>Set<Modifier> modifiersRule, (GenElement)=>List<? extends AnnotationMirror> annotationsRule, ()=>CharSequence commentRule) {
		super(null, null)
		this.template = null
		this.avPrefix = null
		this.activationRule = activationRule ?: RuleUtils.ALWAYS_ACTIVE
		this.srcRule = srcRule ?: RuleUtils.SINGLE_SRC_ELEMENT
		scopeRule = createScopeRule(srcRule)
		this.nameRule = nameRule
		this.modifiersRule = modifiersRule ?: [| emptySet]
		this.annotationsRule = annotationsRule ?: [g |emptyList]
		this.commentRule = commentRule ?: [|""]
		genElementIsSrcForDependentRules = true
		manualOverrideRule = null
	}
	
	protected def genElementIsSrcForDependentRulesAV(){
		 metaAnnotation?.value("genElementIsSrcForDependentRules", Boolean) ?: true	 
	}
	
	protected def void addDependentMemberRule(MemberRuleSupport<?,?> mr){
		if(mr==null) return;
		dependentMemberRules.add [g| mr.apply(g)]
	}
	
	
	protected def ()=>boolean createActivationRule(){
		createActivationRule(metaAnnotation, avPrefix)
	}	
	
	protected def ()=>Object createSrcRule(){
		createSrcRule(metaAnnotation, avPrefix)
	}
	
	protected def ((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> createScopeRule(()=>Object srcRule){
		createScopeRule(metaAnnotation, template, avPrefix, srcRule)  
	}
	
	protected def ()=>Set<Modifier> createModifiersRule(){
		createModifiersRule(metaAnnotation, template, avPrefix)
	}
	
	protected def (GenElement)=>List<? extends AnnotationMirror> createAnnotationsRule(){
		createAnnotationMappingRules(metaAnnotation, template, avPrefix)
	}
	
	protected def ()=>String createNameRule() {
		createNameExprRule(metaAnnotation, template, avPrefix)
	}
	
	protected def ()=>CharSequence createCommentRule() {
		createCommentRule(metaAnnotation, template, avPrefix, null)
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
							val elements = r.apply(generatedClass)
							//TODO: only return the primary members or also the dependent ones?
							//generatedMembers.addAll(elements)
						
						]
						null			
					]
					generatedMembers
				]
				
				manualOverrideRule?.apply(result.map[(it as Iterable<GenElement> ).head])  
				
				result.flatten.toList
				
			} catch (TypeElementNotFoundException tenfe) {
				//If there is a tenfe, no members are generated and the dependency to the unknown type is registered
				handleTypeElementNotFound(tenfe, currentAnnotatedClass)
				emptyList
			} catch(Exception re) {

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
