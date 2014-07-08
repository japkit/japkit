package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenExecutableElement
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Param
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement
import org.eclipse.xtext.xbase.lib.Pair

abstract class ExecutableElementRule extends MemberRuleSupport<ExecutableElement> {
	
	protected val List<Pair<AnnotationMirror, VariableElement>> paramRules
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		
		if(template !=null){
			//If there is a template, use its parameters. They can optionally have @Param annotation
			paramRules=template.parameters.map[it.annotationMirror(Param)->it].toList
		} else {
			//No template. Use the params from the @Method or @Constructor annotation
			paramRules=metaAnnotation.value("parameters", typeof(AnnotationMirror[])).map[it->null].toList
		}
	}
	
	def protected void setParametersFromTemplateAndAnnotation(GenExecutableElement executableElement, AnnotationMirror triggerAnnotation,
		TypeElement annotatedClass, GenTypeElement generatedClass, Element ruleSrcElement) {
		if(triggerAnnotation == null) return
		
		
		val List<GenParameter> methodParams = newArrayList()

		paramRules.forEach [
			val paramAnnotation = key
			val template = value;
			getIteratorFromAnnotation(triggerAnnotation, paramAnnotation, ruleSrcElement).forEach [ e |
				valueStack.scope(e) [
					val paramNameFromAnno = getNameFromAnnotation(triggerAnnotation, paramAnnotation)
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
					val paramAnnotationMappings = paramAnnotation?.annotationMappings("annotationMappings") ?: emptyList
					mapAnnotations(e, paramAnnotationMappings).forEach[param.addAnnotationMirror(it)]
					methodParams.add(param)
				]
			]
		]
		
		
		executableElement.setParameters(methodParams)
	}
	
}