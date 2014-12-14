package de.stefanocke.japkit.rules

import de.stefanocke.japkit.metaannotations.Clazz
import de.stefanocke.japkit.metaannotations.ResourceTemplate
import de.stefanocke.japkit.model.GenTypeElement
import de.stefanocke.japkit.services.ProcessingException
import de.stefanocke.japkit.services.TypeElementNotFoundException
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data

@Data
class TriggerAnnotationRule extends AbstractRule{
	
	TypeElement triggerAnnotationTypeElement
	List<ELVariableRule> varRules
	List<ClassRule> classRules
	List<ResourceRule> resourceRules
	List<LibraryRule> libraryRules
	LibraryRule selfLibraryRule
	
	new(AnnotationMirror triggerMetaAnnotation, TypeElement triggerAnnotationTypeElement){
		super(triggerMetaAnnotation, triggerAnnotationTypeElement)
		this.triggerAnnotationTypeElement = triggerAnnotationTypeElement

		varRules=createELVariableRules(metaAnnotation, null)
		
		//@Clazz
		classRules=triggerAnnotationTypeElement.annotationMirrors(Clazz).map[new ClassRule(it, null ,true)].toList
		
		//@ResourceTemplate
		val resourcePackage = triggerAnnotationTypeElement.package
		resourceRules = triggerAnnotationTypeElement.annotationMirrors(ResourceTemplate).map[new ResourceRule(it, resourcePackage)]		
		selfLibraryRule = new LibraryRule(triggerMetaAnnotation, triggerAnnotationTypeElement)
		libraryRules = createLibraryRules(triggerMetaAnnotation, null)
	}
	
	
	def Set<GenTypeElement> processTriggerAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation){
		inRule[
			scope(annotatedClass) [
				val generatedClasses = newHashSet
				setCurrentAnnotatedClass(annotatedClass)
				setCurrentTriggerAnnotation(triggerAnnotation)
				
				try {
					printDiagnosticMessage['''Process annotated class «annotatedClass», Trigger annotation «triggerAnnotation».''']
		
					valueStack.putAll(currentTriggerAnnotation.annotationValuesByNameUnwrappedAsMap)
					
					libraryRules.forEach[apply]
					selfLibraryRule.apply
					
					//EL Variables			
					varRules.forEach[putELVariable]
				
					classRules.forEach[generateClass(null, generatedClasses)]
						
					resourceRules.forEach[generateResource]
					
				} catch (ProcessingException pe) {
					reportError(pe)
					
				} catch (TypeElementNotFoundException tenfe) {
					handleTypeElementNotFound(tenfe, annotatedClass)
					
				} catch(Exception e) {
					reportRuleError(e)				
				} 
				generatedClasses
			]
		
		]
	}
	
	def String getGeneratedTypeElementFqn(TypeElement annotatedClass){
		if(classRules.size != 1){
			reportRuleError('''There must be exactly one @Clazz annotation in the trigger annoation declaration to determine the name of the generated class unambgiuously.''')
			null
		} else {
			classRules.head.getGeneratedTypeElementFqn(annotatedClass)
		}
	}
	
}