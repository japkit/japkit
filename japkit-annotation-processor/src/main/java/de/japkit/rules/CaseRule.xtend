package de.japkit.rules

import de.japkit.services.RuleException
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0

/** A case rule at first checks, if the condition matches. 
 * If so, it evaluates the value expression or function and returns the result.
 */
@Data
class CaseRule<T> extends AbstractRule implements Function0<T>, ICodeFragmentRule {

	()=>Boolean conditionRule
	ExpressionOrFunctionCallRule<T> valueRule
	List<TypeElement> otherAnnotationTypes

	new(AnnotationMirror metaAnnotation, Element metaElement, Class<? extends T> type, boolean isDefaultCase) {
		super(metaAnnotation, metaElement)

		conditionRule = if(isDefaultCase) [true] else ExpressionOrFunctionCallRule.ruleOrNullIfUndefined(metaAnnotation, null, Boolean, "cond", "condLang",
			"condFun", null, null, false, ExpressionOrFunctionCallRule.AND_COMBINER)
		

		this.valueRule = new ExpressionOrFunctionCallRule<T>(metaAnnotation, metaElement, type, "value", "valueLang",
			"valueFun", null, null, false, null);
			
		this.otherAnnotationTypes =  metaElement?.annotationMirrors?.filter[it!=metaAnnotation]?.map[annotationType.asTypeElement]?.toList

	}

	/**
	 * The key of the returned pair is true if the condition evaluated to true. The value is the evaluated value then.
	 */
	def shallBeApplied() {
		inRule[
			handleException([false], null) [
				val condition = conditionRule?.apply ?: 
					
					{
						//If the condition of the case annotation is "empty", look for the first annotation that represents a function and call it as a boolean function
						//This is done here, since createFunctionRule within constructor creates some cyclic dependedencies and/or stackoverflow in Xtend
						var Pair<TypeElement, IParameterlessFunctionRule<?>> typeAndFunction
						try {
							typeAndFunction = otherAnnotationTypes.map[it -> createFunctionRule].findFirst[it.value != null] 	
							typeAndFunction?.value?.apply as Boolean			
						} catch(Exception e) {
							throw new RuleException('''Error when evaluating condition function «typeAndFunction?.key.simpleName» : '''+e.message)
						}
						
					}
				return condition ?: false			
			]
		]
	}

	def static <E> findFirstMatching(List<CaseRule<E>> caseRules) {
		caseRules?.findFirst[shallBeApplied]
	}

	def private Object getRuleToApply() {
		val rule = if (!valueRule.isUndefined)
				valueRule
			else {
				metaElement?.createFunctionRule 
				//Für den häufigen Fall des "Type-Switch". Ist nicht ganz allgemein, könnten ja auch Functions mit beliebigen Rückgabetypen sein.
				//Die Möglichkeit, Paramter per Type-Argumenten zu übergeben ist aber gegenwärtig an den TypeResolver gebunden.
				?: createTypeRule(null, metaElement.asType(), null);
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
