package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Clazz
import de.stefanocke.japkit.metaannotations.ResourceTemplate
import de.stefanocke.japkit.metaannotations.Var
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ELVariableRule
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import java.util.List

@Data
class TriggerAnnotationRule extends AbstractRule{
	protected val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	protected val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	protected val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	protected val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	protected val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	
	TypeElement triggerAnnotationTypeElement
	List<ELVariableRule> varRules
	List<ClassRule> classRules
	List<ResourceRule> resourceRules
	
	new(TypeElement triggerAnnotationTypeElement){
		super(null, triggerAnnotationTypeElement)
		_triggerAnnotationTypeElement = triggerAnnotationTypeElement
		//TODO: Could be an AV in @TriggerAnnotation
		_varRules=triggerAnnotationTypeElement.annotationMirrors(Var).map[new ELVariableRule(it)].toList
		
		//@Clazz
		_classRules=triggerAnnotationTypeElement.annotationMirrors(Clazz).map[new ClassRule(it, null ,true)].toList
		
		//@ResourceTemplate
		val resourcePackage = triggerAnnotationTypeElement.package
		_resourceRules = triggerAnnotationTypeElement.annotationMirrors(ResourceTemplate).map[new ResourceRule(it, resourcePackage)]
		
	}
	
	
	def Set<GenTypeElement> processTriggerAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation){
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
	}
	
}