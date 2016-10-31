package de.japkit.rules

import de.japkit.rules.AbstractFunctionRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data

@Data
class BooleanOperatorRule extends AbstractFunctionRule<java.lang.Boolean> {
	
	ExpressionOrFunctionCallRule<java.lang.Boolean> functionCalls
	boolean isNot
	
	new(AnnotationMirror metaAnnotation, Element metaElement, boolean isNot, boolean isOr) {
		super(metaAnnotation, metaElement, Boolean)
		this.functionCalls = new ExpressionOrFunctionCallRule<Boolean>(metaAnnotation, metaElement, type, "dummy", "dummyLang",
			"value", null, null, false, if (isOr)  ExpressionOrFunctionCallRule.OR_COMBINER else ExpressionOrFunctionCallRule.AND_COMBINER);
		this.isNot = isNot
	}
	
	override protected evalInternal() {
		val result =  functionCalls.apply
		if(isNot) !result else result
	}
	
}