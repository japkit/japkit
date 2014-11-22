package de.stefanocke.japkit.model;

import javax.lang.model.element.AnnotationMirror;

public interface AnnotationWrapper extends AnnotationMirror {
	
	//the wrapped annotation
	AnnotationMirror getAnnotation();
}
