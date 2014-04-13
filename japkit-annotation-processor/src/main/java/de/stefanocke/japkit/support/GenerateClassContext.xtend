package de.stefanocke.japkit.support

import java.util.Stack
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport

/**
 * Provides access currently generated class and annotated class.
 */
class GenerateClassContext {
	Stack<TypeElement> currentAnnotatedClasses = new Stack<TypeElement>
	
	

	def pushCurrentAnnotatedClass(TypeElement annotatedClass) {
		currentAnnotatedClasses.push(annotatedClass)
		ExtensionRegistry.get(ELSupport).valueStack.pushAndPutAll(#{"currentAnnotatedClass" -> annotatedClass})
	}

	def popCurrentAnnotatedClass() {
		currentAnnotatedClasses.pop
		ExtensionRegistry.get(ELSupport).valueStack.pop
	}
	
	def currentAnnotatedClass() {
		if(currentAnnotatedClasses.empty()) null else currentAnnotatedClasses.peek
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
		if(!metaAnnotations.empty) metaAnnotations.peek else null
	}
	
	def void pushCurrentMetaAnnotation(AnnotationMirror am){
		ExtensionRegistry.get(MessageCollector).printDiagnosticMessage['''Start processing Meta Annotation «am»''']
		metaAnnotations.push(am)
		millis.push(System.currentTimeMillis)
		
	}
	
	def void popCurrentMetaAnnotation(){
		val am = metaAnnotations.pop()
		val startMillis = millis.pop
		ExtensionRegistry.get(MessageCollector).printDiagnosticMessage[
			'''Finished processing Meta Annotation «am». Duration: «System.currentTimeMillis-startMillis»'''
		]
	}
	
	GenTypeElement currentGeneratedClass
	
	def GenTypeElement getCurrentGeneratedClass(){
		currentGeneratedClass
	}
	
	def void setCurrentGeneratedClass(GenTypeElement currentGeneratedClass){
		this.currentGeneratedClass = currentGeneratedClass
		ExtensionRegistry.get(ELSupport).valueStack.put("currentGenClass", currentGeneratedClass)
	}
}