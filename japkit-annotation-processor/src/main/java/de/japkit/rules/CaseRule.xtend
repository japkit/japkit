package de.japkit.rules

import de.japkit.rules.AbstractRule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtend.lib.annotations.Data
import java.util.List
import de.japkit.services.RuleException

/** A case rule at first checks, if the condition matches. 
 * If so, it evaluates the value expression or function and returns the result.
 */
@Data
class CaseRule<T> extends AbstractRule implements Function0<T>, ICodeFragmentRule {

	()=>boolean conditionRule
	ExpressionOrFunctionCallRule<T> valueRule

	new(AnnotationMirror metaAnnotation, Element metaElement, Class<? extends T> type) {
		super(metaAnnotation, metaElement)

		conditionRule = new ExpressionOrFunctionCallRule<Boolean>(metaAnnotation, null, Boolean, "cond", "condLang",
			"condFun", null, null, false, ExpressionOrFunctionCallRule.AND_COMBINER)

		this.valueRule = new ExpressionOrFunctionCallRule<T>(metaAnnotation, metaElement, type, "value", "valueLang",
			"valueFun", null, null, false, null);

	}

	/**
	 * The key of the returned pair is true if the condition evaluated to true. The value is the evaluated value then.
	 */
	def shallBeApplied() {
		inRule[
			return conditionRule.apply ?: false
		]
	}

	def static <E> findFirstMatching(List<CaseRule<E>> caseRules) {
		caseRules?.findFirst[shallBeApplied]
	}

	def private getRuleToApply() {
		val rule = if (!valueRule.isUndefined)
				valueRule
			else {
				metaElement?.createFunctionRule;
			}
		if (rule ==
			null) {
			throw new RuleException('''Case rule «metaElement?.simpleName ?: metaAnnotation» must either have a value or be put on an element that is a function.''');
		}
		rule
	}

	override apply() {
		inRule[
			handleException(null, null) [
				val rule = ruleToApply
				if (rule instanceof Function0) {
					rule.apply as T
				}
			]
		]
	}

	def getCodeFragmentRule() {
		if (!(ruleToApply instanceof ICodeFragmentRule)) {
			throw new RuleException('''Case rule «metaElement?.simpleName ?: metaAnnotation» is not a code fragment''')
		}
		ruleToApply as CodeFragmentRule
	}

	override code() {
		inRule[
			handleException(null, null) [
				codeFragmentRule.code
			]
		]
	}

	override surround(CharSequence surrounded) {
		inRule[
			handleException(null, null) [
				codeFragmentRule.surround(surrounded)
			]
		]
	}

}
