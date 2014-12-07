package de.stefanocke.japkit.rules

import de.stefanocke.japkit.metaannotations.Clazz
import de.stefanocke.japkit.metaannotations.Constructor
import de.stefanocke.japkit.metaannotations.Field
import de.stefanocke.japkit.metaannotations.InnerClass
import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.model.AnnotationWithDefaultAnnotation
import de.stefanocke.japkit.model.GenElement
import de.stefanocke.japkit.model.GenTypeElement
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.TypeResolver
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

@Data
class TemplateRule extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>>{

	val transient extension TypeResolver = ExtensionRegistry.get(TypeResolver)

	TypeElement templateClass
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	List<(GenTypeElement)=> List<? extends GenElement>> memberRules
	((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> scopeRule
	AnnotationMirror fieldDefaults
	AnnotationMirror methodDefaults
	AnnotationMirror constructorDefaults
	
	boolean allFieldsAreTemplates
	boolean allMethodsAreTemplates
	boolean allConstructorsAreTemplates
	
	LibraryRule libraryRule
	
	new(TypeElement templateClass, AnnotationMirror templateAnnotation, (TemplateRule)=>void registrationCallback) {
		super(templateAnnotation, templateClass)
		registrationCallback.apply(this) //Allows self cycles of template rules!
		this.templateClass = templateClass
		
		methodDefaults = metaAnnotation?.value("methodDefaults", typeof(AnnotationMirror[]))?.singleValue
		fieldDefaults = metaAnnotation?.value("fieldDefaults", typeof(AnnotationMirror[]))?.singleValue
		constructorDefaults = metaAnnotation?.value("constructorDefaults", typeof(AnnotationMirror[]))?.singleValue
		
		allFieldsAreTemplates = metaAnnotation?.value("allFieldsAreTemplates", boolean) ?: true
		allMethodsAreTemplates = metaAnnotation?.value("allMethodsAreTemplates", boolean) ?: true
		allConstructorsAreTemplates = metaAnnotation?.value("allConstructorsAreTemplates", boolean) ?: true
		
		memberRules=newArrayList()	
		
		if(metaAnnotation!=null){
			//Members from AVs
			memberRules.add(new MembersRule(metaAnnotation))
		}
		
		memberRules.addAll(templateClass.enclosedElementsOrdered
			.map[createRuleForMember]
			.filter[it!=null].toList
		)	

		annotationsRule = createAnnotationMappingRules(metaAnnotation, templateClass, null)
		scopeRule = createScopeRule(metaAnnotation, templateClass, null)

		//a template is always a library to itself
		libraryRule = new LibraryRule(metaAnnotation, templateClass)
		
	}
	
	def private dispatch (GenTypeElement)=> List<? extends GenElement> createRuleForMember(TypeElement member){
		val innerClassAnnotation = member.annotationMirror(InnerClass)
		if(innerClassAnnotation!=null){
			 return new InnerClassRule(innerClassAnnotation, member) 	 
		}
		val clazzAnnotation = member.annotationMirror(Clazz)
		if(clazzAnnotation!=null){
			val cr = new ClassRule(clazzAnnotation, member, true, true);
			return	[
					cr.generateClass(null, null)
					emptyList
				]
		}
		return null
	}
	
	def private dispatch (GenTypeElement)=> List<? extends GenElement> createRuleForMember(VariableElement member){
		val annotation =  member.annotationMirror(Field)
		if(annotation != null || allFieldsAreTemplates)
			new FieldRule(AnnotationWithDefaultAnnotation.createIfNecessary(annotation, fieldDefaults), member)
		else null
	}
	
	def private dispatch (GenTypeElement)=> List<? extends GenElement> createRuleForMember(ExecutableElement member){
		if(member.kind == ElementKind.METHOD){
			val annotation =  member.annotationMirror(Method)
			if(annotation != null || allMethodsAreTemplates)
				return new MethodRule(AnnotationWithDefaultAnnotation.createIfNecessary(annotation, methodDefaults), member)
			
		} else (member.kind == ElementKind.CONSTRUCTOR ){
			val annotation =  member.annotationMirror(Constructor)
			if(annotation != null || (allConstructorsAreTemplates && !member.isDefaultConstructor))
				return new ConstructorRule(AnnotationWithDefaultAnnotation.createIfNecessary(annotation, constructorDefaults), member)
		} 
		return null
	}
	def private dispatch (GenTypeElement)=> List<? extends GenElement> createRuleForMember(Element member){
		null
	}
	
	def private boolean isDefaultConstructor(ExecutableElement ctor){
		ctor.parameters.nullOrEmpty
	}

	override apply(GenTypeElement generatedClass) {
		inRule[
			
			scopeRule.apply [
				libraryRule.apply
				generatedClass.annotationMirrors = annotationsRule.apply(generatedClass)
				addInterfaces(generatedClass)				
				memberRules.map[it.apply(generatedClass)].flatten.toList	
			].flatten.toList
		
		]

	}

	def private addInterfaces(GenTypeElement generatedClass) {
		templateClass.interfaces.forEach [
			generatedClass.addInterface(it.resolveType) //TODO: Check , if interface already exists? 
		]
	}
}