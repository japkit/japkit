package de.japkit.rules

import de.japkit.model.CodeBody
import de.japkit.model.GenField
import de.japkit.services.ExtensionRegistry
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

@Data
class FieldRule extends MemberRuleSupport<VariableElement, GenField> {
	val transient extension GetterSetterRules = ExtensionRegistry.get(GetterSetterRules)
	
	(GenField)=>CodeBody initCodeRule
	
	()=>TypeMirror typeRule
	
	new(AnnotationMirror metaAnnotation, VariableElement template) {
		super(metaAnnotation, template)
		initCodeRule = createInitCodeRule	
		typeRule = createTypeRule
		
		addGetterRule
		addSetterRule
		
	}
	
	def protected addGetterRule() {
		addDependentMemberRule(createGetterRuleFromGetterAV(metaAnnotation, null))
	}
	
	def protected addSetterRule() {
		addDependentMemberRule(createSetterRuleFromSetterAV(metaAnnotation, null))
	}
	
	
	protected def ()=>TypeMirror createTypeRule() {
		createTypeRule(metaAnnotation, template?.asType, null)
	}
	
	override protected createMember(String name) {
		new GenField(name, null)
	}
	
	protected override applyRulesAfterCreation(GenField member) {
		super.applyRulesAfterCreation(member)
		member.type = typeRule.apply
		
		member.constantExpr = initCodeRule.apply(member)
	}
	
	def protected (GenField)=>CodeBody createInitCodeRule(){
		val cr = new CodeRule(metaAnnotation, template, "init");
		[genElement | CodeRule.getAsCodeBody(genElement, cr)]
	}

}
