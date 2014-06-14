package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenAnnotationValue
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExecutableElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.GenerateClass
import java.util.ArrayList
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType

class TopLevelClassGenerator extends ClassGeneratorSupport{
	

	def Set<GenTypeElement> processGenClassAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation) {

		val genClass = triggerAnnotation.metaAnnotation(GenerateClass)

		if(genClass == null) return emptySet;
		try {
			pushCurrentMetaAnnotation(genClass)

			//superclass with type args
			val generatedClass = createClass(annotatedClass, triggerAnnotation, genClass)
			
			//Register generated class as early as possible to allow error type resolution in other classes
			registerGeneratedTypeElement(generatedClass, annotatedClass, triggerAnnotation)
		
			setCurrentGeneratedClass(generatedClass)

			setSuperClassAndInterfaces(annotatedClass, generatedClass, triggerAnnotation, genClass)

			valueStack.putELVariables(generatedClass, triggerAnnotation, genClass)

			createShadowAnnotation(triggerAnnotation, annotatedClass, genClass, generatedClass)
			
			generatedClass.annotationMirrors = mapTypeAnnotations(annotatedClass, triggerAnnotation, genClass, 
				new ArrayList(generatedClass.annotationMirrors)
			)
			processMemberGenerators(annotatedClass, generatedClass, triggerAnnotation, genClass)

			val Set<GenTypeElement> generatedClasses = newHashSet
			generatedClasses.addAll(
				behaviorDelegationGenerator.createBehaviorDelegation(annotatedClass, triggerAnnotation, generatedClass,
					genClass));
			generatedClasses.add(generatedClass)

			generatedClasses.forEach[markAsGenerated(it, annotatedClass)]

			generatedClasses.forEach[addOrderAnnotations]
			
			generatedClasses.forEach[addParamNamesAnnotations]

			generatedClasses

		} finally {
			popCurrentMetaAnnotation
		}
	}
	
	def createShadowAnnotation(AnnotationMirror triggerAnnotation, TypeElement annotatedClass, AnnotationMirror genClass, GenTypeElement generatedClass) {
		try{
			val shallCreateShadowAnnotation = triggerAnnotation.valueOrMetaValue(annotatedClass, "createShadowAnnotation", Boolean, genClass)
			if(shallCreateShadowAnnotation){
				val shadowAnnotation = GenExtensions.copy(triggerAnnotation) => [it.setShadowIfAppropriate]
				
				valueStack.getVariablesForShadowAnnotation().forEach[name, value |
					shadowAnnotation.setValue(name, [t| 
						//TODO: Schicker. In extension o.ä verlagern
						new GenAnnotationValue(coerceAnnotationValue(value, t))
					])
				]
				
				generatedClass.addAnnotationMirror(shadowAnnotation)
			}
		
		} catch (RuntimeException re){
			reportError('''Error when creating shadow annotation:''', re, annotatedClass, triggerAnnotation, null)
		}
	}

	private def void addOrderAnnotations(Element e) {
		val enclosed = e.enclosedElements
		for (order : 0 ..< enclosed.size) {
			enclosed.get(order).addOrderAnnotation(order);
			enclosed.get(order).addOrderAnnotations()
		}
	}

	def dispatch void addOrderAnnotation(GenElement element, Integer order) {
		element.addAnnotationMirror(
			new GenAnnotationMirror(elementUtils.getTypeElement(ORDER_ANNOTATION_NAME).asType as DeclaredType) => [
				setValue("value", [new GenAnnotationValue(order)])
			]
		)
	}

	def dispatch void addOrderAnnotation(Element element, Integer integer) {
	}
	
	
	def dispatch void addParamNamesAnnotations(GenTypeElement typeElement) {
		typeElement.enclosedElements.forEach[it.addParamNamesAnnotations]
	}
	
	def dispatch void addParamNamesAnnotations(GenExecutableElement element) {
		if(!element.parameters.nullOrEmpty){
			element.addAnnotationMirror(
				new GenAnnotationMirror(elementUtils.getTypeElement(PARAM_NAMES_ANNOTATION_NAME).asType as DeclaredType) => [
					setValue("value", [new GenAnnotationValue(element.parameters.map[simpleName.toString].map[new GenAnnotationValue(it)].toList)])
				]
			)		
		}
	}
	def dispatch void addParamNamesAnnotations(Element element) {
		
	}

	
}
