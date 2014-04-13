package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.gen.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement

class MethodRule extends MemberRuleSupport<ExecutableElement> {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}

	protected override createMember(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		val method = createMemberAndSetCommonAttributes(triggerAnnotation, annotatedClass, generatedClass,
			ruleSrcElement, [new GenMethod(it)])

		method.returnType = typeFromMetaAnnotationOrTemplate(annotatedClass, generatedClass, triggerAnnotation,
			"returnType", "returnTypeArgs", ruleSrcElement, method.returnType)

		setParametersFromMetaAnnotation(method, triggerAnnotation, annotatedClass, generatedClass, ruleSrcElement)

		val codeBody = getCodeBodyFromMetaAnnotation(method, triggerAnnotation, "bodyExpr", "bodyLang")
		if (codeBody != null) {
			method.removeModifier(Modifier.ABSTRACT)
			method.body = codeBody
		}
		method
	}

	def protected void setParametersFromMetaAnnotation(GenMethod method, AnnotationMirror triggerAnnotation,
		TypeElement annotatedClass, GenTypeElement generatedClass, Element ruleSrcElement) {
		if(triggerAnnotation == null) return
		val params = triggerAnnotation.valueOrMetaValue("parameters", typeof(AnnotationMirror[]), metaAnnotation)

		//TODO: Replace parameters with equal name
		val methodParams = params.map [
			val paramName = value("name", String)
			val paramAnnotationMappings = annotationMappings("annotationMappings")
			//Ugly: We use the @Param annotation as the meta-annotation here. 
			//But here, it should not really be allowed that for example a "name" AV from an "@Entity" overrides a parameter name...
			//TODO: Refactoring of relatedTypes regarding annotation, meta-annotation and selector annotation
			val paramType = resolveType(triggerAnnotation, annotatedClass, generatedClass, it, "type", "typeArgs",
				ruleSrcElement)
			new GenParameter(paramName, paramType) => [
				annotationMirrors = mapAnnotations(ruleSrcElement, paramAnnotationMappings)
			]
		]
		methodParams.forEach[method.addParameter(it)]
	}

}
