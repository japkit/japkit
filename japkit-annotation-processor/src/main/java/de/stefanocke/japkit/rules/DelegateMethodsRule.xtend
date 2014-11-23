package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.GenMethod
import de.stefanocke.japkit.model.Property
import java.util.ArrayList
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement

class DelegateMethodsRule extends MemberRuleSupport<ExecutableElement, GenMethod> {
	val transient extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}

	override protected createSrcRule() {
		val methodFilter = metaAnnotation.elementMatchers("methodFilter");
		
		[ |
			val srcElement = currentSrcElement
			valueStack.put("delegate", srcElement)
			val delegateTypeElement = srcElement.srcType.asTypeElement
			delegateTypeElement.allMethods.filter[m|methodFilter.nullOrEmpty || methodFilter.exists[matches(m)]]
		]
	}

	protected override createMember() {

		val delegateMethod = currentSrcElement as ExecutableElement
		val method = genExtensions.copyFrom(delegateMethod, false);

		val customMethodName = nameRule.apply
		if (!customMethodName.nullOrEmpty) {
			method.simpleName = customMethodName
		}
		
		

		//TODO
		//method.annotationMirrors = annotationMappingRules.apply(delegateMethod)

		val delegate = valueStack.get("delegate") as Element
		
		val getDelegateMethod = if(delegate instanceof ExecutableElement){
			delegate
		} else if(delegate instanceof Property){
			delegate.getter
		} else {
			null
		}
		
		if(getDelegateMethod != null){
			//the delegate is retrieved by calling a method. Prepend the parameters.
			val params = new ArrayList(getDelegateMethod.parametersWithSrcNames)
			params.addAll(method.parameters)
			method.parameters = params	
		}

		method.body = [ec|
			val getDelegate = if(getDelegateMethod != null){
				'''this.«getDelegateMethod.simpleName»(«getDelegateMethod.argumentsList»)'''
			} else {
				'''this.«delegate.simpleName»'''
			}
			val delegateMethodArgs = delegateMethod.argumentsList
			val delegateMethodName = '''«delegateMethod.simpleName»''' 
			val returnIfRequired = if(delegateMethod.returnType.void) '' else 'return '
			'''
				«returnIfRequired»«getDelegate».«delegateMethodName»(«delegateMethodArgs»);
			''']

		method
	}
	
	protected def argumentsList(ExecutableElement method) {
		method.parametersWithSrcNames.map[simpleName].join(", ")
	}
	
	override protected createMember(String name) {
		throw new UnsupportedOperationException("Not used here")
	}

}
