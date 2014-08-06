package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import java.util.Stack
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

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
	
	val currentGeneratedClasses = new Stack<GenTypeElement>
	
	def GenTypeElement getCurrentGeneratedClass(){
		if(currentGeneratedClasses.isEmpty()) null else currentGeneratedClasses.peek
	}
	
	def void pushCurrentGeneratedClass(GenTypeElement currentGeneratedClass){
		currentGeneratedClasses.push(currentGeneratedClass)
		//new value stack scope for each generated class to handle inner classes properly
		ExtensionRegistry.get(ELSupport).valueStack.pushAndPutAll(#{"currentGenClass" -> currentGeneratedClass})
	}
	
	def void popCurrentGeneratedClass(){
		currentGeneratedClasses.pop		
		ExtensionRegistry.get(ELSupport).valueStack.pop
		
	}
	
	def putShadowAnnotation(AnnotationMirror shadowAnnotation) {
		val extension ELSupport = ExtensionRegistry.get(ELSupport)
		valueStack.put("shadowAnnotation", shadowAnnotation)
	}
}