package de.japkit.rules

import de.japkit.model.GenParameter
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.VariableElement
import org.eclipse.xtext.xbase.lib.Functions.Function0
import de.japkit.model.GenElement
import javax.lang.model.type.TypeMirror

/**
 * Rule for creating one ore more method params.
 */
class ParamRule extends AbstractRule implements Function0<List<? extends GenParameter>> {

	()=>boolean activationRule
	((Object)=>GenParameter)=>Iterable<GenParameter> scopeRule
	()=>String nameRule
	()=>TypeMirror typeRule
	(GenElement)=>List<? extends AnnotationMirror> annotationMappingRules

	new(AnnotationMirror paramAnnotation, VariableElement template, String avPrefix) {
		super(paramAnnotation, template)

		activationRule = createActivationRule(paramAnnotation, avPrefix) ?: RuleUtils.ALWAYS_ACTIVE
		val srcRule = createSrcRule(paramAnnotation, avPrefix)
		scopeRule = createScopeRule(paramAnnotation, template, avPrefix, srcRule)
		nameRule = createNameExprRule(paramAnnotation, template, avPrefix)
		annotationMappingRules = createAnnotationMappingRules(paramAnnotation, template, avPrefix)
		typeRule = createTypeRule(paramAnnotation, template?.asType, avPrefix);
	}

	// Nur für Setter-Rule. 1:1 übernommen. TODO Prüfen..
	new(()=>String nameRule, ()=>TypeMirror typeRule,
		(GenElement)=>List<? extends AnnotationMirror> annotationMappingRules) {
		super(null, null)
		activationRule = RuleUtils.ALWAYS_ACTIVE
		scopeRule = scopeWithCurrentSrc
		this.nameRule = nameRule
		this.annotationMappingRules = annotationMappingRules
		this.typeRule = typeRule
	}

	override apply() {
		inRule[
			if(!activationRule.apply) return emptyList

			scopeRule.apply [
				val name = nameRule.apply
				val type = typeRule.apply

				val param = new GenParameter(name, type)

				if (annotationMappingRules !== null) {
					param.annotationMirrors = annotationMappingRules.apply(param)
				}
				param
			].toList
		]
	}

}
