package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenField
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

@Data
class FieldRule extends MemberRuleSupport<VariableElement, GenField> {
	extension GetterSetterRules = ExtensionRegistry.get(GetterSetterRules)
	
	(GenField, Element)=>CodeBody initCodeRule
	
	(Element)=>TypeMirror typeRule
	
	new(AnnotationMirror metaAnnotation, VariableElement template) {
		super(metaAnnotation, template)
		_initCodeRule = createInitCodeRule	
		_typeRule = createTypeRule
		
		addGetterRule
		addSetterRule
		
	}
	
	def addGetterRule() {
		if (metaAnnotation?.value("generateGetter", boolean) == Boolean.TRUE) {
			addDependentMemberRule(createGetterRule(metaAnnotation))
		}
	}
	
	
	
	def addSetterRule() {
		if (metaAnnotation?.value("generateSetter", boolean) == Boolean.TRUE) {
			addDependentMemberRule(createSetterRule(metaAnnotation))
		}
	}
	
	
	protected def (Element)=>TypeMirror createTypeRule() {
		ru.createTypeRule(metaAnnotation, template?.asType, null)
	}
	
	override protected createMember(Element ruleSrcElement, String name) {
		new GenField(name, null)
	}
	
	protected override applyRulesAfterCreation(GenField member, Element ruleSrcElement) {
		super.applyRulesAfterCreation(member, ruleSrcElement)
		member.type = typeRule.apply(ruleSrcElement)
		
		member.constantExpr = _initCodeRule.apply(member, ruleSrcElement)
	}
	
	def protected (GenField, Element)=>CodeBody createInitCodeRule(){
		val cr = new CodeRule(metaAnnotation, "init");
		[genElement, ruleSourceElement | CodeRule.getAsCodeBody(genElement, ruleSourceElement, cr)]
	}

}
