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
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.singleValue

@Data
class TemplateRule extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>>{

	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val RuleUtils ru = ExtensionRegistry.get(RuleUtils)
	val GetterSetterRules gs = ExtensionRegistry.get(GetterSetterRules)

	TypeElement templateClass
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	List<(GenTypeElement)=> List<? extends GenElement>> memberRules
	((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> scopeRule
	AnnotationMirror fieldDefaults
	AnnotationMirror methodDefaults
	AnnotationMirror constructorDefaults

	
	new(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		super(templateAnnotation, templateClass)
		_templateClass = templateClass
		
		_methodDefaults = metaAnnotation?.value("methodDefaults", typeof(AnnotationMirror[]))?.singleValue
		_fieldDefaults = metaAnnotation?.value("fieldDefaults", typeof(AnnotationMirror[]))?.singleValue
		_constructorDefaults = metaAnnotation?.value("constructorDefaults", typeof(AnnotationMirror[]))?.singleValue
		
		val allFieldsAreTemplates = metaAnnotation?.value("allFieldsAreTemplates", boolean) ?: true
		val allMethodsAreTemplates = metaAnnotation?.value("allMethodsAreTemplates", boolean) ?: true
		val allConstructorsAreTemplates = metaAnnotation?.value("allConstructorsAreTemplates", boolean) ?: true
		
		_memberRules=newArrayList()	
		
		if(metaAnnotation!=null){
			//Members from AVs
			memberRules.add(new MembersRule(metaAnnotation))
		}
		
		memberRules.addAll(
			templateClass.declaredTypes.map[it -> annotationMirror(InnerClass)].filter[value != null].map [
				new InnerClassRule(value, key)
			])

		memberRules.addAll(
			templateClass.declaredFields.map[it -> annotationMirror(Field)].filter[
				allFieldsAreTemplates || value != null].map [
				new FieldRule(AnnotationWithDefaultAnnotation.createIfNecessary(value, fieldDefaults), key)
			])

		//		memberRules.addAll(templateClass.declaredFields.map[it -> annotationMirror(Getter)].filter[value != null].map [
		//			gs.createGetterRule(value, key, null)
		//		])
		//		
		//		memberRules.addAll(templateClass.declaredFields.map[it -> annotationMirror(Setter)].filter[value != null].map [
		//			gs.createSetterRule(value, key, null)
		//		])
		memberRules.addAll(
			templateClass.declaredConstructors.map[it -> annotationMirror(Constructor)].filter[
				(allConstructorsAreTemplates && !key.isDefaultConstructor) || value != null].map [
				new ConstructorRule(AnnotationWithDefaultAnnotation.createIfNecessary(value, constructorDefaults), key)
			])

		memberRules.addAll(
			templateClass.declaredMethods.map[it -> annotationMirror(Method)].filter[
				allMethodsAreTemplates || value != null].map [
				new MethodRule(AnnotationWithDefaultAnnotation.createIfNecessary(value, methodDefaults), key)
			])

		_annotationsRule = ru.createAnnotationMappingRules(metaAnnotation, templateClass, null)
		_scopeRule = ru.createScopeRule(metaAnnotation, _templateClass, null)

	}
	
	def boolean isDefaultConstructor(ExecutableElement ctor){
		ctor.parameters.nullOrEmpty
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