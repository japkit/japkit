package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenField
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.VariableElement

@Data
class FieldRule extends MemberRuleSupport<VariableElement, GenField> {
	CodeRule initCodeRule
	
	new(AnnotationMirror metaAnnotation, VariableElement template) {
		super(metaAnnotation, template)
		_initCodeRule = new CodeRule(metaAnnotation,"init")
		
		addAfterCreationRule(ru.createTypeRule(metaAnnotation, template?.asType, null)) [f, t | f.setType(t)]
	}

	protected override createMember(Element ruleSrcElement) {
		val field = createMemberAndSetCommonAttributes(ruleSrcElement, [new GenField(it, null)])

		val cb = initCodeRule.getAsCodeBody(field)
		if (cb != null) {
			field.constantExpr = cb
		}
		field
	}

}
