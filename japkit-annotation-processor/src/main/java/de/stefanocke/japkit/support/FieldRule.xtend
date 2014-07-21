package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenField
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

import static de.stefanocke.japkit.support.CodeFragmentRules.*

@Data
class FieldRule extends MemberRuleSupport<VariableElement, GenField> {
	extension JavaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	
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
			val getter = new MethodRule(
				ru.createActivationRule(metaAnnotation, "getter"),
				null,
				[f | (f as VariableElement).getterName],
				ru.createModifiersRule(metaAnnotation, null, "getter"),
				ru.createAnnotationMappingRules(metaAnnotation, null, "getter"),
				null,
				[m , f | '''return «surround("getterSurroundReturnFragment",f.simpleName)»;'''],
				[f | f.asType]
			)
			addDependentMemberRule(getter)
		}
	}
	
	def addSetterRule() {
		if (metaAnnotation?.value("generateSetter", boolean) == Boolean.TRUE) {
			val setter = new MethodRule(
				ru.createActivationRule(metaAnnotation, "setter"),
				null,
				[f | (f as VariableElement).setterName],
				ru.createModifiersRule(metaAnnotation, null, "setter"),
				ru.createAnnotationMappingRules(metaAnnotation, null, "setter"),
				ru.createParamRule(null, [it.simpleName.toString], [it.asType], 
					ru.createAnnotationMappingRules(metaAnnotation, null, "setterParam")
				),				
				[m, f | '''this.«f.simpleName» = «surround("setterSurroundAssignmentFragment",f.simpleName)»;'''],
				null
			)
			addDependentMemberRule(setter)
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
