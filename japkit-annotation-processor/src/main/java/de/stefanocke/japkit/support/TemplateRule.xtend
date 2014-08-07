package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Constructor
import de.stefanocke.japkit.metaannotations.Field
import de.stefanocke.japkit.metaannotations.Getter
import de.stefanocke.japkit.metaannotations.InnerClass
import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.metaannotations.Setter
import de.stefanocke.japkit.metaannotations.Template
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.singleValue

@Data
class TemplateRule implements Function1<GenTypeElement, List<? extends GenElement>>{

	protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val RuleUtils ru = ExtensionRegistry.get(RuleUtils)
	val GetterSetterRules gs = ExtensionRegistry.get(GetterSetterRules)

	TypeElement templateClass
	AnnotationMirror templateAnnotation
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	List<(GenTypeElement)=> List<? extends GenElement>> memberRules
	((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> scopeRule
	AnnotationMirror fieldDefaults
	AnnotationMirror methodDefaults
	AnnotationMirror constructorDefaults

	new(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		_templateClass = templateClass
		_templateAnnotation = templateAnnotation ?: templateClass.annotationMirror(Template)
		_methodDefaults = templateAnnotation?.value("methodDefaults", typeof(AnnotationMirror[]))?.singleValue
		_fieldDefaults = templateAnnotation?.value("fieldDefaults", typeof(AnnotationMirror[]))?.singleValue
		_constructorDefaults = templateAnnotation?.value("constructorDefaults", typeof(AnnotationMirror[]))?.singleValue
		
		_memberRules=newArrayList()	
		
		memberRules.addAll(templateClass.declaredTypes.map[it -> annotationMirror(InnerClass)].filter[value != null].map [
			new InnerClassRule(value, key)
		])
		
		memberRules.addAll(templateClass.declaredFields.map [
			new FieldRule(AnnotationWithDefaultAnnotation.createIfNecessary(annotationMirror(Field), fieldDefaults), it)
		])
		
		memberRules.addAll(templateClass.declaredFields.map[it -> annotationMirror(Getter)].filter[value != null].map [
			gs.createGetterRule(value, key, null)
		])
		
		memberRules.addAll(templateClass.declaredFields.map[it -> annotationMirror(Setter)].filter[value != null].map [
			gs.createSetterRule(value, key, null)
		])
		
		memberRules.addAll(templateClass.declaredConstructors.map[it -> annotationMirror(Constructor)].filter[value != null].map [
			new ConstructorRule(AnnotationWithDefaultAnnotation.createIfNecessary(value, constructorDefaults), key)
		])
		
		memberRules.addAll(templateClass.declaredMethods.map[it -> annotationMirror(Method)].filter[value != null].map [
			new MethodRule(AnnotationWithDefaultAnnotation.createIfNecessary(value, methodDefaults), key)
		])
		
		
		_annotationsRule=ru.createAnnotationMappingRules(templateAnnotation, templateClass, null)
		_scopeRule=ru.createScopeRule(templateAnnotation, null)

	}

	override apply(GenTypeElement generatedClass) {
		
			
		scopeRule.apply [
			
			generatedClass.annotationMirrors = annotationsRule.apply(generatedClass)

			addInterfaces(generatedClass)
			
			val generatedMembers = newArrayList
			
			memberRules.forEach [generatedMembers.addAll(it.apply(generatedClass))]	
			
			generatedMembers
		].flatten.toList

	}

	def addInterfaces(GenTypeElement generatedClass) {
		templateClass.interfaces.forEach [
			generatedClass.addInterface(it.resolveType) //TODO: Check , if interface already exists? 
		]
	}
}