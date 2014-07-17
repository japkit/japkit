package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.metaannotations.Param
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.VariableElement

@Data
abstract class ExecutableElementRule extends MemberRuleSupport<ExecutableElement> {
	
	val List<(Element)=>Iterable<? extends GenParameter>> paramRules
	CodeRule bodyCodeRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		
		_paramRules= if(template !=null){
			//If there is a template, use its parameters. They can optionally have @Param annotation
			template.parametersWithSrcNames.map[createParamRule(it.annotationMirror(Param), it)].toList
		} else {
			//No template. Use the params from the @Method or @Constructor annotation
			metaAnnotation.value("parameters", typeof(AnnotationMirror[])).map[createParamRule(it, null)].toList
		}
		_bodyCodeRule = new CodeRule(metaAnnotation,"body")
	}
	
	def protected (Element)=>Iterable<? extends GenParameter> createParamRule(AnnotationMirror paramAnnotation, VariableElement template){
		val srcElementsRule = ru.createIteratorExpressionRule(paramAnnotation)
		val nameRule = ru.createNameExprRule(paramAnnotation, template)
		val annotationMappingRules = ru.createAnnotationMappingRules(paramAnnotation, template)
		val typeRule = ru.createTypeRule(paramAnnotation, template?.asType, null);
		
		[ Element ruleSrcElement |
			srcElementsRule.apply(ruleSrcElement).map [ e |
				valueStack.scope(e) [
					val name = nameRule.apply(e)
					val type = typeRule.apply(e)
					
					val param = new GenParameter(name, type)
						
					param.annotationMirrors = annotationMappingRules.apply(e)
					param
				]
			]
		]

	}
	
	def protected generateParameters(Element ruleSrcElement){
		paramRules.map[apply(ruleSrcElement)].flatten.toList
	}
	
	
}