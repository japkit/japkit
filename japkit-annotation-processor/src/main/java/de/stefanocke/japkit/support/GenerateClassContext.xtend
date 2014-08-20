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
	
	def ValueStack currentValueStack() {
		ExtensionRegistry.get(ELSupport).getValueStack()
	}

	def setCurrentAnnotatedClass(TypeElement annotatedClass) {	
		currentValueStack.put("currentAnnotatedClass" , annotatedClass)
	}
	
	def currentAnnotatedClass() {
		currentValueStack.get("currentAnnotatedClass") as TypeElement
	}

	def GenTypeElement getCurrentGeneratedClass(){
		currentValueStack.get("currentGenClass") as GenTypeElement
	}
	
	def void setCurrentGeneratedClass(GenTypeElement currentGeneratedClass){
		currentValueStack.put("currentGenClass" , currentGeneratedClass)
	}
	
	AnnotationMirror currentAnnotation
	
	def AnnotationMirror getCurrentAnnotation(){
		currentAnnotation
	}
	
	def void  setCurrentAnnotation(AnnotationMirror currentAnnotation){
		this.currentAnnotation = currentAnnotation
		ExtensionRegistry.get(ELSupport).valueStack.put("currentAnnotation", currentAnnotation)
	}
	
	//Primarily for debugging purposes ...
	Stack<AnnotationMirror> metaAnnotations = new Stack<AnnotationMirror>
	Stack<Long> millis = new Stack<Long>
	
	def AnnotationMirror getCurrentMetaAnnotation(){
		if(!metaAnnotations.isEmpty()) metaAnnotations.peek else null
	}
	
	def void pushCurrentMetaAnnotation(AnnotationMirror am){
		//ExtensionRegistry.get(MessageCollector).printDiagnosticMessage['''Start processing Meta Annotation «am»''']
		metaAnnotations.push(am)
		//millis.push(System.currentTimeMillis)
		
	}
	
	def void popCurrentMetaAnnotation(){
		val am = metaAnnotations.pop()
		//val startMillis = millis.pop
		//ExtensionRegistry.get(MessageCollector).printDiagnosticMessage[
		//	'''Finished processing Meta Annotation «am». Duration: «System.currentTimeMillis-startMillis»'''
		//]
	}
	
	
	
	
	
	
	
	def putShadowAnnotation(AnnotationMirror shadowAnnotation) {
		currentValueStack.put("shadowAnnotation", shadowAnnotation)
	}
}