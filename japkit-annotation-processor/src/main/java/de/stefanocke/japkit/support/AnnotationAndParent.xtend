package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

@Data
class AnnotationAndParent implements AnnotationWrapper{
	AnnotationMirror annotation
	
	//Name of the annotation value
	String avName
	
	//position of the annotation within the annotation value (in case it is an array)
	Integer index
	
	//the parent annotation. null, if it is a top level annotation.
	AnnotationAndParent parentAnnotation
	
	//If it is a top level annotation: the annotated element
	Element annotatedElement
	
	override getAnnotationType() {
		annotation.annotationType
	}
	
	override getElementValues() {
		annotation.elementValues
	}
	
	def Element getRootAnnotatedElement(){
		parentAnnotation?.rootAnnotatedElement ?: annotatedElement
	}
	
	def AnnotationMirror getRootAnnotation(){
		parentAnnotation?.rootAnnotation ?: annotation
	}
	
	def String getPathFromRootAnnotation(){
		pathFromRootAnnotation_.toString
	}
	def private CharSequence getPathFromRootAnnotation_(){
		if(parentAnnotation==null) '' 
		else {
			 val parentPath = parentAnnotation.pathFromRootAnnotation_
			 '''«IF parentPath.length>0»«parentPath».«ENDIF»«pathSegment»'''
			 
		}
	}
	
	def private getPathSegment() {
		'''«avName»«IF index != null»[«index»]«ENDIF»'''
	}
	
}