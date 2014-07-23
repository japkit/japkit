package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenParameter
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.VariableElement

import static de.stefanocke.japkit.support.CodeFragmentRules.*

class GetterSetterRules {
	
	extension JavaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	extension ElementsExtensions  = ExtensionRegistry.get(ElementsExtensions)
	extension RuleUtils = ExtensionRegistry.get(RuleUtils)
	
	def MethodRule createGetterRule(AnnotationMirror metaAnnotation) {
		val surroundReturnExprFragments = metaAnnotation.value("getterSurroundReturnExprFragments", typeof(String[]))
		val getter = new MethodRule(metaAnnotation, "getter",
			null,
			[(it as VariableElement).getterName],
			null,
			[m, f|
			'''return «surround(surroundReturnExprFragments, f.simpleName)»;
			'''],
			[it.asType]
		)
		getter
	}
	
	def MethodRule createSetterRule(AnnotationMirror metaAnnotation) {
		val surroundAssignmentExprFragments = metaAnnotation.value("setterSurroundAssignmentExprFragments", typeof(String[]))
		val setter = new MethodRule(metaAnnotation, "setter",
			null,
			[(it as VariableElement).setterName],
			createSetterParamRule(metaAnnotation),				
			[m, f |
			'''this.«f.simpleName» = «surround(surroundAssignmentExprFragments ,f.simpleName)»;
			'''],
			null
		)
		setter
	}
	
	private def (Element)=>List<? extends GenParameter> createSetterParamRule(AnnotationMirror metaAnnotation) {
		createParamRule(
			null,
			[it.simpleName.toString],
			[it.asType],
			createAnnotationMappingRules(metaAnnotation, null, "setterParam")
		)
	}
}