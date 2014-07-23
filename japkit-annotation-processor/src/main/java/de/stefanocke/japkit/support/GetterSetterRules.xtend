package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenParameter
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.VariableElement

import static de.stefanocke.japkit.support.CodeFragmentRules.*
import static extension de.stefanocke.japkit.support.RuleUtils.*

class GetterSetterRules {
	
	extension JavaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	extension ElementsExtensions  = ExtensionRegistry.get(ElementsExtensions)
	extension RuleUtils = ExtensionRegistry.get(RuleUtils)
	
	def MethodRule createGetterRuleFromGetterAV(AnnotationMirror metaAnnotation) {
		metaAnnotation?.value("getter", AnnotationMirror)?.createGetterRule(null)
	}
	
	def MethodRule createSetterRuleFromSetterAV(AnnotationMirror metaAnnotation) {
		metaAnnotation?.value("setter", AnnotationMirror)?.createSetterRule(null)
	}
	
	def MethodRule createGetterRule(AnnotationMirror metaAnnotation, String avPrefix) {
		val surroundReturnExprFragments = metaAnnotation.value("surroundReturnExprFragments".withPrefix(avPrefix), typeof(String[]))
		new MethodRule(metaAnnotation,  avPrefix,
			null,
			[(it as VariableElement).getterName],
			createCommentRule(metaAnnotation, null,  avPrefix)[e | '''@return «e.docComment?.toString?.trim»'''],
			null,
			[m, f|
			'''return «surround(surroundReturnExprFragments, f.simpleName)»;
			'''],
			[it.asType]
		)
	}
	
	def MethodRule createSetterRule(AnnotationMirror metaAnnotation, String avPrefix) {
		val surroundAssignmentExprFragments = metaAnnotation.value("surroundAssignmentExprFragments".withPrefix(avPrefix), typeof(String[]))
		new MethodRule(metaAnnotation, avPrefix,
			null,
			[(it as VariableElement).setterName],
			createCommentRule(metaAnnotation, null, avPrefix)[e | '''@param «e.simpleName» «e.docComment?.toString?.trim»'''],
			createSetterParamRule(metaAnnotation, avPrefix),				
			[m, f |
			'''this.«f.simpleName» = «surround(surroundAssignmentExprFragments ,f.simpleName)»;
			'''],
			null
		)
	}
	
	private def (Element)=>List<? extends GenParameter> createSetterParamRule(AnnotationMirror metaAnnotation, String avPrefix) {
		createParamRule(
			null,
			[it.simpleName.toString],
			[it.asType],
			createAnnotationMappingRules(metaAnnotation, null, "param".withPrefix(avPrefix))
		)
	}
}