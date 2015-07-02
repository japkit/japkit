package de.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data

@Data
class FunctionRule extends AbstractFunctionRule<Object> {
	
	()=>Object exprOrFunctionCallRule
	
	new(AnnotationMirror metaAnnotation, Element metaElement) {
		super(metaAnnotation, metaElement, null)
	
		val nullable = metaAnnotation.value("nullable", Boolean) ?: false;
		
		exprOrFunctionCallRule = createExpressionOrFunctionCallAndFilterRule(metaAnnotation, metaElement,
			"expr", "fun", "lang", "filter", "filterFun", "collect", "collectFun", "toSet", "groupBy", "groupByFun","type", null,
			[|currentSrc], nullable
		)
		
	}
	
	override evalInternal(){ 
		exprOrFunctionCallRule.apply
	}

}