package de.japkit.model;

import java.lang.annotation.Annotation;
import java.util.List;

import javax.lang.model.element.AnnotationMirror;

/**
 * "Implements" the new Element methods from Java 8. 
 * Currently written in a way to still work with Java 7.
 * 
 * @author stefan
 *
 */
public abstract class GenAnnotatedConstruct {

	public <A extends Annotation> A getAnnotation(Class<A> annotationType){
		throw new UnsupportedOperationException();
	}
	
	public <A extends Annotation> A[] getAnnotationsByType(Class<A> annotationType) {
		throw new UnsupportedOperationException();
	}
	
	public List<? extends AnnotationMirror> getAnnotationMirrors(){
		throw new UnsupportedOperationException();
	}
}
