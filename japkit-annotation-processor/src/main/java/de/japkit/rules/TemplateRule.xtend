package de.japkit.rules

import de.japkit.metaannotations.Clazz
import de.japkit.metaannotations.Constructor
import de.japkit.metaannotations.Field
import de.japkit.metaannotations.InnerClass
import de.japkit.metaannotations.Method
import de.japkit.model.AnnotationWithDefaultAnnotation
import de.japkit.model.GenElement
import de.japkit.model.GenTypeElement
import de.japkit.services.ExtensionRegistry
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.japkit.util.MoreCollectionExtensions.*

@Data
class TemplateRule extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>>{

	val transient extension TypeResolver = ExtensionRegistry.get(TypeResolver)

	TypeElement templateClass
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	List<(GenTypeElement)=> List<? extends GenElement>> memberRules
	()=>boolean activationRule
	((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> scopeRule
	AnnotationMirror fieldDefaults
	AnnotationMirror methodDefaults
	AnnotationMirror constructorDefaults
	
	boolean allFieldsAreTemplates
	boolean allMethodsAreTemplates
	boolean allConstructorsAreTemplates
	
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
			.filter[!isVariable]  //TODO: Violates SRP, since the knowledge about how to handle variables is spread to several places? Anyway: This is redundant as soon as a var is a function...
			.map[createRuleForMember]
			.filter[it!=null].toList
		)	

		annotationsRule = createAnnotationMappingRules(metaAnnotation, templateClass, null)
		activationRule = createActivationRule(templateAnnotation, null)
		scopeRule = createScopeRule(metaAnnotation, templateClass, true, null)

	
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
		val isNoFunction = createFunctionRule(member) == null
		if(member.kind == ElementKind.METHOD){
			val annotation =  member.annotationMirror(Method)
			if(annotation != null || allMethodsAreTemplates && isNoFunction)
				return new MethodRule(AnnotationWithDefaultAnnotation.createIfNecessary(annotation, methodDefaults), member)
			
		} else (member.kind == ElementKind.CONSTRUCTOR ){
			val annotation =  member.annotationMirror(Constructor)
			if(annotation != null || (allConstructorsAreTemplates && !member.isDefaultConstructor && isNoFunction))
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
			if(!activationRule.apply) return emptyList
			
			scopeRule.apply [
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