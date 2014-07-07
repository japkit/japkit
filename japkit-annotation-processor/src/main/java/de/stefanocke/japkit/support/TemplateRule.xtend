package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Field
import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.metaannotations.Template
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.metaannotations.InnerClass
import de.stefanocke.japkit.metaannotations.Constructor

@Data
class TemplateRule {

	protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension RelatedTypes relatedTypes = ExtensionRegistry.get(RelatedTypes)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)

	TypeElement templateClass
	AnnotationMirror templateAnnotation
	List<ConstructorRule> constructorRules
	List<MethodRule> methodRules
	List<FieldRule> fieldRules
	List<InnerClassRule> innerClassRules

	new(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		_templateClass = templateClass
		_templateAnnotation = templateAnnotation ?: templateClass.annotationMirror(Template)
		_methodRules = templateClass.declaredMethods.map[it -> annotationMirror(Method)].filter[value != null].map [
			new MethodRule(value, key)
		].toList
		
		_constructorRules = templateClass.declaredConstructors.map[it -> annotationMirror(Constructor)].filter[value != null].map [
			new ConstructorRule(value, key)
		].toList

		_fieldRules = templateClass.declaredFields.map [
			new FieldRule(annotationMirror(Field), it)
		]
		
		_innerClassRules = templateClass.declaredTypes.map[it -> annotationMirror(InnerClass)].filter[value != null].map [
			new InnerClassRule(value, key)
		].toList

	}

	def apply(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation) {
		apply(annotatedClass, generatedClass, triggerAnnotation, generatedClass)
	}

	def void apply(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation,
		Element ruleSrcElement) {
		try {
			
			valueStack.push
			valueStack.putELVariables(ruleSrcElement, triggerAnnotation, templateAnnotation)

			addInterfaces(templateClass, annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
			addFields(templateClass, annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
			addConstructors(templateClass, annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
			addMethods(templateClass, annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
			addInnerClasses(templateClass, annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
			
		} finally {
			valueStack.pop
		}

	}

	def addConstructors(TypeElement templateClass, TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		constructorRules.forEach [
			apply(annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
		]
	}
	
	def addMethods(TypeElement templateClass, TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		methodRules.forEach [
			apply(annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
		]
	}
	
	def addInnerClasses(TypeElement templateClass, TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		innerClassRules.forEach [
			apply(annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
		]
	}

	def getGenExtensions() {
		ExtensionRegistry.get(GenExtensions)
	}

	def addFields(TypeElement templateClass, TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		fieldRules.forEach [
			apply(annotatedClass, generatedClass, triggerAnnotation, ruleSrcElement)
		]
	}

	def addInterfaces(TypeElement templateClass, TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		templateClass.interfaces.forEach [
			val resolvedType = relatedType(it, annotatedClass, generatedClass, triggerAnnotation, null, ruleSrcElement)
			generatedClass.addInterface(resolvedType) //TODO: Check , if interface already exists? 
		]
	}
}
