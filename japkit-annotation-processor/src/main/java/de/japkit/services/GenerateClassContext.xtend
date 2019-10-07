package de.japkit.services

import de.japkit.el.ELSupport
import de.japkit.el.ValueStack
import de.japkit.model.GenTypeElement
import de.japkit.rules.Rule
import java.util.Stack
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.QualifiedNameable

/**
 * Provides access currently generated class and annotated class.
 */
class GenerateClassContext {
	
	def private ValueStack valueStack() {
		ExtensionRegistry.get(ELSupport).getValueStack()
	}

	def setCurrentAnnotatedClass(QualifiedNameable annotatedClass) {	
		valueStack.put("annotatedClass" , annotatedClass)
	}
	
	def currentAnnotatedClass() {
		valueStack.get("annotatedClass") as QualifiedNameable
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
	
	
	val Stack<Rule> currentRules = new Stack()
	
	def getCurrentRule(){
		if(currentRules.empty()) null else currentRules.peek
	}
	
	def void pushCurrentRule(Rule rule){
		if(currentRules.size > 30 && currentRules.filter[it===rule].size>20){
			currentRules.groupBy[it].filter[k, v| v.size >19].keySet.forEach[			
				ExtensionRegistry.get(MessageCollector).reportRuleError(rule, "Potential infinite recursion.", null)		
			]
			
			throw new RuleStackOverflowError("Potential infinite recursion. "+currentRules?.map[metaElement+ " " + metaAnnotation ].join("\n"))
		}
		currentRules.push(rule)
	}
	
	def Rule popCurrentRule(){
		currentRules.pop
	}
	 
}