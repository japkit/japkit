package de.stefanocke.japkit.rules;

import javax.lang.model.element.AnnotationMirror;

public interface AnnotationWrapper extends AnnotationMirror {
	
	//the wrapped annotation
	AnnotationMirror getAnnotation();
}
