package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Clazz
import de.stefanocke.japkit.metaannotations.ResourceTemplate
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ELVariableRule
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

@Data
class TriggerAnnotationRule extends AbstractRule{

	protected val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	protected val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	
	TypeElement triggerAnnotationTypeElement
	List<ELVariableRule> varRules
	List<ClassRule> classRules
	List<ResourceRule> resourceRules
	
	new(AnnotationMirror triggerMetaAnnotation, TypeElement triggerAnnotationTypeElement){
		super(triggerMetaAnnotation, triggerAnnotationTypeElement)
		_triggerAnnotationTypeElement = triggerAnnotationTypeElement

		_varRules=createELVariableRules(metaAnnotation, null)
		
		//@Clazz
		_classRules=triggerAnnotationTypeElement.annotationMirrors(Clazz).map[new ClassRule(it, null ,true)].toList
		
		//@ResourceTemplate
		val resourcePackage = triggerAnnotationTypeElement.package
		_resourceRules = triggerAnnotationTypeElement.annotationMirrors(ResourceTemplate).map[new ResourceRule(it, resourcePackage)]
		
	}
	
	
	def Set<GenTypeElement> processTriggerAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation){
		inRule[
			scope(annotatedClass) [
				val generatedClasses = newHashSet
				setCurrentAnnotatedClass(annotatedClass)
				setCurrentTriggerAnnotation(triggerAnnotation)
				
				try {
					printDiagnosticMessage['''Process annotated class «annotatedClass», Trigger annotation «triggerAnnotation».''']
		
					//EL Variables			
					varRules.forEach[putELVariable]
				
					classRules.forEach[generateClass(null, generatedClasses)]
						
					resourceRules.forEach[generateResource]
					
				} catch (ProcessingException pe) {
					reportError(pe)
					
				} catch (TypeElementNotFoundException tenfe) {
					handleTypeElementNotFound(tenfe, annotatedClass)
					
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