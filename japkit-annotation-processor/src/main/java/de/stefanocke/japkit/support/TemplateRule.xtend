package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Constructor
import de.stefanocke.japkit.metaannotations.Field
import de.stefanocke.japkit.metaannotations.InnerClass
import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.singleValue
import de.stefanocke.japkit.metaannotations.Clazz
import javax.lang.model.element.VariableElement
import javax.lang.model.element.ElementKind
import java.util.Map
import de.stefanocke.japkit.metaannotations.CodeFragment
import javax.lang.model.element.Element

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
	
	boolean allFieldsAreTemplates
	boolean allMethodsAreTemplates
	boolean allConstructorsAreTemplates
	
	Map<String,?> functions
	
	new(TypeElement templateClass, AnnotationMirror templateAnnotation, (TemplateRule)=>void registrationCallback) {
		super(templateAnnotation, templateClass)
		registrationCallback.apply(this) //Allows self cycles of template rules!
		_templateClass = templateClass
		
		_methodDefaults = metaAnnotation?.value("methodDefaults", typeof(AnnotationMirror[]))?.singleValue
		_fieldDefaults = metaAnnotation?.value("fieldDefaults", typeof(AnnotationMirror[]))?.singleValue
		_constructorDefaults = metaAnnotation?.value("constructorDefaults", typeof(AnnotationMirror[]))?.singleValue
		
		_allFieldsAreTemplates = metaAnnotation?.value("allFieldsAreTemplates", boolean) ?: true
		_allMethodsAreTemplates = metaAnnotation?.value("allMethodsAreTemplates", boolean) ?: true
		_allConstructorsAreTemplates = metaAnnotation?.value("allConstructorsAreTemplates", boolean) ?: true
		
		_memberRules=newArrayList()	
		
		if(metaAnnotation!=null){
			//Members from AVs
			memberRules.add(new MembersRule(metaAnnotation))
		}
		
		memberRules.addAll(templateClass.enclosedElementsOrdered
			.map[createRuleForMember]
			.filter[it!=null].toList
		)	

		_annotationsRule = ru.createAnnotationMappingRules(metaAnnotation, templateClass, null)
		_scopeRule = ru.createScopeRule(metaAnnotation, _templateClass, null)

		_functions = newHashMap( 		
			templateClass.enclosedElementsOrdered
				.map[createFunctionForMember]
				.filter[it!=null])
		
	}
	
	def private dispatch createFunctionForMember(TypeElement member){
		val codeFragmentAnnotation = member.annotationMirror(CodeFragment)
		if(codeFragmentAnnotation!=null){
			return member.simpleName.toString.toFirstLower -> new CodeFragmentRule(codeFragmentAnnotation, member)
		}
		null
	}
	
	def private dispatch createFunctionForMember(Element member){
		null
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
				valueStack.putAll(functions)
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