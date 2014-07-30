package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Constructor
import de.stefanocke.japkit.metaannotations.Field
import de.stefanocke.japkit.metaannotations.InnerClass
import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.metaannotations.Template
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

@Data
class TemplateRule implements Procedure1<GenTypeElement>{

	protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val RuleUtils ru = ExtensionRegistry.get(RuleUtils)

	TypeElement templateClass
	AnnotationMirror templateAnnotation
	List<ConstructorRule> constructorRules
	List<MethodRule> methodRules
	List<FieldRule> fieldRules
	List<InnerClassRule> innerClassRules
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule

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

	override void apply(GenTypeElement generatedClass) {
		
			
		scope[
			putELVariables(templateAnnotation)
			
			generatedClass.annotationMirrors = annotationsRule.apply(generatedClass)

			addInterfaces(generatedClass)
			innerClassRules.forEach [it.apply(generatedClass)]
			fieldRules.forEach [it.apply(generatedClass)]
			constructorRules.forEach [it.apply(generatedClass)]
			methodRules.forEach [it.apply( generatedClass)]		
		]

	}

	def addInterfaces(GenTypeElement generatedClass) {
		templateClass.interfaces.forEach [
			generatedClass.addInterface(it.resolveType) //TODO: Check , if interface already exists? 
		]
	}
}