package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import de.stefanocke.japkit.activeannotations.Required
import java.lang.annotation.Annotation
import java.util.Collections
import java.util.Comparator
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ElementVisitor
import javax.lang.model.element.Modifier
import javax.lang.model.element.Name

import static de.stefanocke.japkit.support.ElementsExtensions.*

@FieldsFromInterface
abstract class GenElement implements Element{
	
	@Required
	Name simpleName
	
	List<AnnotationMirror> annotationMirrors = newArrayList
	List<Element> enclosedElements = newArrayList
	Element enclosingElement
	Set<Modifier> modifiers = newHashSet
	var CharSequence comment
	
	override <R, P> accept(ElementVisitor<R,P> v, P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override asType() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override <A extends Annotation> A getAnnotation(Class<A> annotationType){
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override abstract ElementKind getKind()
 	
 	def addEnclosedElement(Element enclosedEl){
 		if(!(enclosedEl instanceof GenElement)){
 			throw new IllegalArgumentException("Only GenElements might be added to a GenElement, but not "+enclosedEl)
 		}
 		val enclosed = enclosedEl as GenElement
 		
 		if(enclosed.getEnclosingElement!=null){
 			throw new IllegalStateException('''Element «enclosed» has already an enclosing element:«enclosed.getEnclosingElement»''')
 		}
 		if(enclosedElementComparator==null){
 			enclosedElements.add(enclosed)
 		} else {
 			var index = Collections.binarySearch(enclosedElements, enclosed, enclosedElementComparator) 
 			if(index<0){ index = -(index + 1)}
 			while(index < enclosedElements.size  && enclosedElementComparator.compare(enclosed, enclosedElements.get(index)) == 0){
 				index = index + 1 
 			}
 			enclosedElements.add(index, enclosed)
 		}
 		enclosed.setEnclosingElement(this);
 		
 	}
 	
 	//Comparator for sorting enclosed elements
 	def Comparator<Element> enclosedElementComparator (){
 		null
 	}	
 	
 	def add(GenElement ... elements){
 		elements.forEach[e |
 			addEnclosedElement(e)
 		]
 	}
 	
 	def GenParameterizable enclosingParameterizable(){
 		if(enclosingElement==null){
 			null
 		} else if(enclosingElement instanceof GenParameterizable){
 			enclosingElement as GenParameterizable
 		} else {
 			(enclosingElement as GenElement).enclosingParameterizable
 		}
 		
 	}
 	
 	
 	
 	/**
 	 * Sets the visibility. Null means default access.
 	 */
 	def setVisibility(Modifier visibility){
 		if(visibility!=null && !VISIBILITY_MODIFIERS.contains(visibility)){
 			throw new IllegalArgumentException('''«visibility» is not a valid visibility modifier''');
 		}
 		modifiers.removeAll(VISIBILITY_MODIFIERS)
 		if(visibility!=null){
 			modifiers.add(visibility);
 		}
 		
 	}
 	
 	
 	/**
 	 * Resolves the type variables of this element in the context of the given ParameterizableElement
 	 */
 	def void resolveContainedTypeVariables(GenParameterizable parameterizable){

 	} 
 	
 	def getComment(){
 		comment
 	}
 	
 	def setComment(CharSequence comment){
 		this.comment = comment
 	}
 	
 	def setSimpleName(CharSequence name){
 		simpleName= new GenName(name)
 	}
 	
 	new(){
 		
 	}	
 	
 	new(Name simpleName){
 		this.simpleName = simpleName
 		//messager.printMessage(Kind.WARNING, '''Created GenElement of type «this.class» with name «this.simpleName» «this»''')
 	}
 	new(String simpleName) {
    	this(new GenName(simpleName))
 	}
	
}