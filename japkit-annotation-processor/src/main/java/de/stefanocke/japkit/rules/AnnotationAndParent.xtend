package de.stefanocke.japkit.rules

import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

@Data
class AnnotationAndParent implements AnnotationWrapper{
	AnnotationMirror annotation
	
	//the path within the parent annotation. null, if it is a top level annotation.
	Path.Segment pathSegment
	
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
	
	def Path getPathFromRootAnnotation(){
		new Path(getPathFromRootAnnotation_)
	}
	def private List<Path.Segment> getPathFromRootAnnotation_(){
		if(parentAnnotation==null) newArrayList() 
		else {
			 val path = parentAnnotation.pathFromRootAnnotation_
			 path.add(pathSegment)
			 path
		}
	}
	
	override toString() {
		annotation?.toString
	}
	
}