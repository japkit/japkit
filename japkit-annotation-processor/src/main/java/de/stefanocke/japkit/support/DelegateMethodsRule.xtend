package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import javax.lang.model.element.ElementKind

class DelegateMethodsRule extends MemberRuleSupport<ExecutableElement> {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}

	override protected getSrcElements(AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		valueStack.put("delegate", ruleSrcElement)

		val delegateTypeElement = ruleSrcElement.asType.asTypeElement

		val methodFilter = triggerAnnotation.elementMatchers("methodFilter", metaAnnotation)
		delegateTypeElement.allMethods.filter[m|methodFilter.nullOrEmpty || methodFilter.exists[matches(m)]]
	}

	protected override createMember(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {

		val delegateMethod = ruleSrcElement as ExecutableElement
		val method = genExtensions.copyFrom(delegateMethod, false);

		val customMethodName = getNameFromMetaAnnotation(triggerAnnotation, delegateMethod)
		if (!customMethodName.nullOrEmpty) {
			method.simpleName = customMethodName
		}

		mapAnnotations(method, triggerAnnotation, delegateMethod)

		val delegate = valueStack.get("delegate") as Element

		method.body = [ec|
			val getDelegate = '''this.«delegate.simpleName»«IF delegate instanceof ExecutableElement»()«ENDIF»'''
			val delegateMethodArgs = delegateMethod.parametersWithSrcNames.map[simpleName].join(", ")
			val delegateMethodName = '''«delegateMethod.simpleName»''' 
			val returnIfRequired = if(delegateMethod.returnType.void) '' else 'return '
			'''
				«returnIfRequired»«getDelegate».«delegateMethodName»(«delegateMethodArgs»);
			''']

		method
	}

}
