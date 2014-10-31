package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ValueStack
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import java.util.Stack

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
	
	def void setCurrentPrimaryGenClass(GenTypeElement primaryGenClass){
		valueStack.put("primaryGenClass", primaryGenClass)
	}
	
	def GenTypeElement getCurrentPrimaryGenClass(){
		valueStack.get("primaryGenClass") as GenTypeElement
	}

	
	def AnnotationMirror getCurrentTriggerAnnotation(){
		valueStack.get("triggerAnnotation") as AnnotationMirror
	}
	
	def void  setCurrentTriggerAnnotation(AnnotationMirror currentAnnotation){
		valueStack.put("triggerAnnotation", currentAnnotation)
	}
	
	def putShadowAnnotation(AnnotationMirror shadowAnnotation) {
		valueStack.put("shadowAnnotation", shadowAnnotation)
	}
	
	
	private val Stack<Rule> currentRules = new Stack()
	
	def getCurrentRule(){
		if(currentRules.empty()) null else currentRules.peek
	}
	
	def void pushCurrentRule(Rule rule){
		if(currentRules.size > 30 && currentRules.filter[it===rule].size>20){
			throw new ProcessingException("Potential infinite recursion.", rule.metaElement, rule.metaAnnotation, null, null)
		}
		currentRules.push(rule)
	}
	
	def Rule popCurrentRule(){
		currentRules.pop
	}
	 
}