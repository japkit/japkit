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
import de.stefanocke.japkit.gen.GenElement
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2

@Data
class TemplateRule implements Procedure2<GenTypeElement,Element>{

	protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension RelatedTypes relatedTypes = ExtensionRegistry.get(RelatedTypes)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val RuleUtils ru = ExtensionRegistry.get(RuleUtils)

	TypeElement templateClass
	AnnotationMirror templateAnnotation
	List<ConstructorRule> constructorRules
	List<MethodRule> methodRules
	List<FieldRule> fieldRules
	List<InnerClassRule> innerClassRules
	(GenElement, Element)=>List<? extends AnnotationMirror> annotationsRule

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
		
		_annotationsRule=ru.createAnnotationMappingRules(templateAnnotation, templateClass, null)

	}

	def apply(GenTypeElement generatedClass) {
		apply(generatedClass, generatedClass)
	}

	override void apply(GenTypeElement generatedClass, Element ruleSrcElement) {
		try {
			
			valueStack.push
			valueStack.putELVariables(ruleSrcElement, currentAnnotation, templateAnnotation)
			
			generatedClass.annotationMirrors = annotationsRule.apply(generatedClass, ruleSrcElement)

			addInterfaces(templateClass, generatedClass, ruleSrcElement)
			addInnerClasses(templateClass, generatedClass, ruleSrcElement)
			addFields(templateClass, generatedClass, ruleSrcElement)
			addConstructors(templateClass, generatedClass,  ruleSrcElement)
			addMethods(templateClass, generatedClass, ruleSrcElement)
			
			
		} finally {
			valueStack.pop
		}

	}

	def addConstructors(TypeElement templateClass, GenTypeElement generatedClass,
		 Element ruleSrcElement) {
		constructorRules.forEach [
			it.apply(generatedClass, ruleSrcElement)
		]
	}
	
	def addMethods(TypeElement templateClass, GenTypeElement generatedClass,
		 Element ruleSrcElement) {
		methodRules.forEach [
			it.apply( generatedClass, ruleSrcElement)
		]
	}
	
	def addInnerClasses(TypeElement templateClass, GenTypeElement generatedClass,
		 Element ruleSrcElement) {
		//TODO: Zirkuläre Dependencies zwischen inner classes sind gegenwärtig nicht möglicht. Evtl könnte man die 
		//GenClasses in einem ersten separaten Durchlauf registrieren... Oder ClassSelectors für InnerClasses sind
		//immer "Proxies" für noch zu erzeugende Klassen.	
		innerClassRules.forEach [
			it.apply(generatedClass, ruleSrcElement)
		]
	}

	def getGenExtensions() {
		ExtensionRegistry.get(GenExtensions)
	}

	def addFields(TypeElement templateClass, GenTypeElement generatedClass,
		 Element ruleSrcElement) {
		fieldRules.forEach [
			it.apply(generatedClass, ruleSrcElement)
		]
	}

	def addInterfaces(TypeElement templateClass, GenTypeElement generatedClass, Element ruleSrcElement) {
		templateClass.interfaces.forEach [
			val resolvedType = relatedType(it, currentAnnotatedClass, generatedClass, currentAnnotation, null, ruleSrcElement)
			generatedClass.addInterface(resolvedType) //TODO: Check , if interface already exists? 
		]
	}
}