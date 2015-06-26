package de.stefanocke.japkit.rules

import de.stefanocke.japkit.rules.AbstractRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtend.lib.annotations.Data
import java.util.List

/** A case rule at first checks, if the condition matches. 
 * If so, it evaluates the value expression or function and returns the result.
 */
@Data
class CaseRule<T> extends AbstractRule implements Function0<Pair<Boolean, T>>{
	
	()=>boolean conditionRule
	()=>T valueRule
	
	new(AnnotationMirror metaAnnotation, Element metaElement, Class<? extends T> type) {
		super(metaAnnotation, metaElement)
		
		conditionRule = new ExpressionOrFunctionCallRule<Boolean>(metaAnnotation, null, Boolean, 
			"cond", "condLang", "condFun", null, null, false, ExpressionOrFunctionCallRule.AND_COMBINER)
		
		// Note: the metaElement is passed in here to allow the Case annotation to be located on a function instead
		// of referring to a function.
		valueRule = new ExpressionOrFunctionCallRule<T>(metaAnnotation, metaElement, type, 
			"value", "valueLang", "valueFun", null, null, false, null)
	}
	
	/**
	 * The key of the returned pair is true if the condition evaluated to true. The value is the evaluated value then.
	 */
	override apply() {
		inRule[
			if(! (conditionRule.apply ?: false)){
				return false -> null
			}
			
			true -> valueRule.apply		
		]
	}
	
	def static <E> applyFirstMatching(List<CaseRule<E>> caseRules){
		caseRules?.map[apply]?.findFirst[key]?.value
	}
	
}