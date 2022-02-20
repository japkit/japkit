package de.japkit.model;

import static java.util.Collections.unmodifiableList;

import java.lang.annotation.Annotation;
import java.util.ArrayList;
import java.util.List;

import javax.lang.model.AnnotatedConstruct;
import javax.lang.model.element.AnnotationMirror;

/**
 * Base implementation for AnnotatedConstruct.
 * 
 * @author stefan
 */
public abstract class GenAnnotatedConstruct implements AnnotatedConstruct {

	private List<AnnotationMirror> annotationMirrors = new ArrayList<>();

	@Override
	public <A extends Annotation> A getAnnotation(Class<A> annotationType) {
		throw new UnsupportedOperationException(
				"This is not supported for generated elements or types. Please use getAnnotationMirrors() instead.");
	}

	@Override
	public <A extends Annotation> A[] getAnnotationsByType(Class<A> annotationType) {
		throw new UnsupportedOperationException(
				"This is not supported for generated elements or types. Please use getAnnotationMirrors() instead.");
	}

	@Override
	public List<? extends AnnotationMirror> getAnnotationMirrors() {
		return unmodifiableList(annotationMirrors);
	}

	public void addAnnotationMirror(final AnnotationMirror aAnnotationMirror) {
		this.annotationMirrors.add(aAnnotationMirror);
	}

	public void removeAnnotationMirror(final AnnotationMirror aAnnotationMirror) {
		this.annotationMirrors.remove(aAnnotationMirror);
	}

	public void setAnnotationMirrors(final List<? extends AnnotationMirror> annotationMirrors) {
		this.annotationMirrors.clear();
		for (AnnotationMirror aAnnotationMirror : annotationMirrors) {
			addAnnotationMirror(aAnnotationMirror);
		}
	}
}
