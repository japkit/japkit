package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import java.util.Stack
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.support.el.ValueStack

/**
 * Provides access currently generated class and annotated class.
 */
class GenerateClassContext {
	
	def private ValueStack valueStack() {
		ExtensionRegistry.get(ELSupport).getValueStack()
	}

	def setCurrentAnnotatedClass(TypeElement annotatedClass) {	
		valueStack.put("annotatedClass" , annotatedClass)
	}
	
	def currentAnnotatedClass() {
		valueStack.get("annotatedClass") as TypeElement
	}

	def GenTypeElement getCurrentGeneratedClass(){
		valueStack.get("genClass") as GenTypeElement
	}
	
	def void setCurrentGeneratedClass(GenTypeElement currentGeneratedClass){
		valueStack.put("genClass" , currentGeneratedClass)
	}

	
	def AnnotationMirror getCurrentTriggerAnnotation(){
		valueStack.get("triggerAnnotation") as AnnotationMirror
	}
	
	def void  setCurrentTriggerAnnotation(AnnotationMirror currentAnnotation){
		valueStack.put("triggerAnnotation", currentAnnotation)
	}
	
	//Primarily for debugging purposes ...
	Stack<AnnotationMirror> metaAnnotations = new Stack<AnnotationMirror>

	
	def AnnotationMirror getCurrentMetaAnnotation(){
		if(!metaAnnotations.isEmpty()) metaAnnotations.peek else null
	}
	
	def void pushCurrentMetaAnnotation(AnnotationMirror am){
		//ExtensionRegistry.get(MessageCollector).printDiagnosticMessage['''Start processing Meta Annotation «am»''']
		metaAnnotations.push(am)
		//millis.push(System.currentTimeMillis)
		
	}
	
	def void popCurrentMetaAnnotation(){
		metaAnnotations.pop()
		//val startMillis = millis.pop
		//ExtensionRegistry.get(MessageCollector).printDiagnosticMessage[
		//	'''Finished processing Meta Annotation «am». Duration: «System.currentTimeMillis-startMillis»'''
		//]
	}
	
	
	
	
	
	
	
	def putShadowAnnotation(AnnotationMirror shadowAnnotation) {
		valueStack.put("shadowAnnotation", shadowAnnotation)
	}
}