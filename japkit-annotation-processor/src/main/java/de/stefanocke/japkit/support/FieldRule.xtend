package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenField
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

@Data
class FieldRule extends MemberRuleSupport<VariableElement, GenField> {
	CodeRule initCodeRule
	
	(Element)=>TypeMirror typeRule
	
	new(AnnotationMirror metaAnnotation, VariableElement template) {
		super(metaAnnotation, template)
		_initCodeRule = new CodeRule(metaAnnotation,"init")
		
		_typeRule = createTypeRule
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
	}

}
