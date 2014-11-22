package de.stefanocke.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.VariableElement

import static de.stefanocke.japkit.rules.CodeFragmentRules.*

import static extension de.stefanocke.japkit.rules.RuleUtils.*

class GetterSetterRules {
	
	val extension JavaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	val extension ElementsExtensions  = ExtensionRegistry.get(ElementsExtensions)
	val extension RuleUtils = ExtensionRegistry.get(RuleUtils)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	
	def MethodRule createGetterRuleFromGetterAV(AnnotationMirror metaAnnotation, VariableElement template) {
		metaAnnotation?.value("getter", AnnotationMirror)?.createGetterRule(template, null)
	}
	
	def MethodRule createSetterRuleFromSetterAV(AnnotationMirror metaAnnotation, VariableElement template) {
		metaAnnotation?.value("setter", AnnotationMirror)?.createSetterRule(template, null)
	}
	
	def MethodRule createGetterRule(AnnotationMirror metaAnnotation, VariableElement template, String avPrefix) {
		val surroundReturnExprFragments = metaAnnotation.value("surroundReturnExprFragments".withPrefix(avPrefix), typeof(String[]))
		val fluent =  metaAnnotation.value("fluent", boolean);
		//Note: These rules fall back to the source element type, if there is no template
		val nameRule = createNameExprRule(null, template, null)
		val typeRule = createTypeRule(null, template?.asType, null)
		val commentRule = createCommentRule(metaAnnotation, null,  avPrefix, null)
		new MethodRule(metaAnnotation,  avPrefix,
			null,
			if(fluent) nameRule else [|getterName(nameRule.apply, typeRule.apply)], //Quite inefficient?
			[| '''@return «commentRule.apply»'''], //Fragwürdig. So lässt sich per annotation nur das @return customizen :( ggf "returnComment" AV
			null,
			[m|
			'''return «surround(surroundReturnExprFragments, nameRule.apply)»;
			'''],
			typeRule
		)
	}
	
//	def templateOrCurrentSrc(VariableElement template){
//		template ?: getCurrentSrc(VariableElement)
//	}
	
	def MethodRule createSetterRule(AnnotationMirror metaAnnotation, VariableElement template, String avPrefix) {
		val surroundAssignmentExprFragments = metaAnnotation.value("surroundAssignmentExprFragments".withPrefix(avPrefix), typeof(String[]))
		val fluent =  metaAnnotation.value("fluent", boolean);
		val chain =  metaAnnotation.value("chain", boolean);
		//Note: These rules fall back to the source element type, if there is no template
		val nameRule = createNameExprRule(null, template, null)
		val typeRule = createTypeRule(null, template?.asType, null)
		val commentRule = createCommentRule(metaAnnotation, null,  avPrefix, null)
		new MethodRule(metaAnnotation, avPrefix,
			null,
			if(fluent) nameRule else [|setterName(nameRule.apply)],
			[|'''@param «nameRule.apply» «commentRule.apply»'''], //Fragwürdig. So lässt sich per annotation nur das @param customizen :( ggf "setterComment" AV
			createParamRule(
				nameRule,
				typeRule,
				createAnnotationMappingRules(metaAnnotation, null, "param".withPrefix(avPrefix))
			),				
			[m|
			'''
			this.«nameRule.apply» = «surround(surroundAssignmentExprFragments ,nameRule.apply)»;
			«IF chain»
			return this;
			«ENDIF»
			'''],
			if(chain) [|currentGeneratedClass.asType] else null
		)
	}
	
	
}