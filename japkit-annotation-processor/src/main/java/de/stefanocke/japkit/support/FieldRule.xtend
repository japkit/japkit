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
		_typeRule = ru.createTypeRule(metaAnnotation, template?.asType, null)
	}

	protected override createMember(Element ruleSrcElement) {
		val field = createMemberAndSetCommonAttributes(ruleSrcElement, [new GenField(it, null)])

		field.type = typeRule.apply(ruleSrcElement)

		val cb = initCodeRule.getAsCodeBody(field)
		if (cb != null) {
			field.constantExpr = cb
		}
		field
	}

}
