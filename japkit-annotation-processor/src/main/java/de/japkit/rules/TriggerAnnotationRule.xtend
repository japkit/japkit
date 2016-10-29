package de.japkit.rules

import de.japkit.metaannotations.Clazz
import de.japkit.metaannotations.ResourceTemplate
import de.japkit.model.GenTypeElement
import de.japkit.services.ProcessingException
import de.japkit.services.TypeElementNotFoundException
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import java.util.ArrayList

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

		varRules=createELVariableRules(metaAnnotation, triggerAnnotationTypeElement, null)
		
		//As a (more concise) alternative to using @Clazz at trigger annotations, @Clazz can be used at the template class.
		//The template class can then be referred directly by the trigger annotation.
		var classTemplates = metaAnnotation?.value("template", typeof(TypeElement[]));
		
		//@Clazz
		classRules= new ArrayList( if(!classTemplates.empty) 
			classTemplates.map[new ClassRule(it.annotationMirror(Clazz), it, true)].toList
			else 
			triggerAnnotationTypeElement.annotationMirrors(Clazz).map[new ClassRule(it, null, true)].toList)
		
		//@ResourceTemplate
		val resourcePackage = triggerAnnotationTypeElement.package
		resourceRules = new ArrayList(triggerAnnotationTypeElement.annotationMirrors(ResourceTemplate).map[new ResourceRule(it, resourcePackage)])		
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