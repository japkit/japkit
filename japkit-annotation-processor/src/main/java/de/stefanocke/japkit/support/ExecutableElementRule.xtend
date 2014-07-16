package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Param
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement

@Data
abstract class ExecutableElementRule extends MemberRuleSupport<ExecutableElement> {
	
	val List<(Element, AnnotationMirror, TypeElement, GenTypeElement)=>Iterable<? extends GenParameter>> paramRules
	CodeRule bodyCodeRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		
		_paramRules= if(template !=null){
			//If there is a template, use its parameters. They can optionally have @Param annotation
			template.parameters.map[createParamRule(it.annotationMirror(Param), it)].toList
		} else {
			//No template. Use the params from the @Method or @Constructor annotation
			metaAnnotation.value("parameters", typeof(AnnotationMirror[])).map[createParamRule(it, null)].toList
		}
		_bodyCodeRule = new CodeRule(metaAnnotation,"body")
	}
	
	def protected (Element, AnnotationMirror, TypeElement, GenTypeElement)=>Iterable<? extends GenParameter> createParamRule(AnnotationMirror paramAnnotation, VariableElement template){
		val srcElementsRule = ru.createIteratorExpressionRule(paramAnnotation)
		val nameRule = ru.createNameExprRule(paramAnnotation, template)
		val annotationMappingRules = ru.createAnnotationMappingRules(paramAnnotation, template);
		
		[ Element ruleSrcElement, AnnotationMirror triggerAnnotation, TypeElement annotatedClass, GenTypeElement generatedClass |
			srcElementsRule.apply(ruleSrcElement).map [ e |
				valueStack.scope(e) [
					val paramNameFromAnno = nameRule.apply(e)
					val paramTypeFromAnno = if (paramAnnotation == null)
							null
						else
							resolveType(triggerAnnotation, annotatedClass, generatedClass, paramAnnotation, "type",
								"typeArgs", e)
					val param = if (template == null) {
							new GenParameter(paramNameFromAnno, paramTypeFromAnno)
						} else {

							//Copy param from template and transform types (for example, replace "AnnotatedClass")
							genExtensions.copyParamFrom(template, true,
								relatedTypesTransformation(annotatedClass, generatedClass, triggerAnnotation, e)) => [
								if (!paramNameFromAnno.nullOrEmpty) {
									simpleName = paramNameFromAnno
								}
								if (paramTypeFromAnno != null) {
									type = paramTypeFromAnno
								}
							]
						}
					param.annotationMirrors = annotationMappingRules.apply(e)
					param
				]
			]
		]

	}
	
	def protected generateParameters(AnnotationMirror triggerAnnotation, TypeElement annotatedClass, GenTypeElement generatedClass, Element ruleSrcElement){
		paramRules.map[apply(ruleSrcElement, triggerAnnotation, annotatedClass, generatedClass)].flatten.toList
	}
	
	
}