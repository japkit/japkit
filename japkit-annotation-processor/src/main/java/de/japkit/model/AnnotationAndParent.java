package de.japkit.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.type.DeclaredType;

/**
 * Wraps an annotation to allow to navigate to its parent(s).
 * 
 * @author stefan
 */
public class AnnotationAndParent implements AnnotationWrapper {
	/**
	 * The original annotation.
	 */
	private final AnnotationMirror annotation;

	/**
	 * The path of the annotation within its parent annotation. The name is the
	 * annotation value name which has this annotation as value. If it is part
	 * of an array, index is also set.
	 */
	private final Path.Segment pathSegment;

	/**
	 * The parent annotation that contains this annotation in one of its values.
	 * Null if this annotation is a root annotation, that is if it is not
	 * contained within an annotation value of another annotation.
	 */
	private final AnnotationAndParent parentAnnotation;

	/**
	 * The annotated element. Null if this annotation is not a root annotation.
	 */
	private final Element annotatedElement;

	@Override
	public DeclaredType getAnnotationType() {
		return this.annotation.getAnnotationType();
	}

	@Override
	public Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValues() {
		return this.annotation.getElementValues();
	}

	/**
	 * @return the root annotation of this annotation. This is the one that has
	 *         no parent annotation but is directly placed on an element.
	 */
	public AnnotationMirror getRootAnnotation() {
		return parentAnnotation == null ? this : parentAnnotation.getRootAnnotation();
	}

	/**
	 * @return the element which the {@link #getRootAnnotation()} of this
	 *         annotation is placed on.
	 */
	public Element getRootAnnotatedElement() {
		return parentAnnotation == null ? annotatedElement : parentAnnotation.getRootAnnotatedElement();
	}

	/**
	 * @return the complete path from the root annotation to this annotation. It
	 *         consists of annotation value names and - in case of array values
	 *         - indexes.
	 */
	public Path getPathFromRootAnnotation() {
		return new Path(this.getPathFromRootAnnotation_());
	}

	private List<Path.Segment> getPathFromRootAnnotation_() {

		if ((this.parentAnnotation == null)) {
			return new ArrayList<>();
		} else {
			final List<Path.Segment> path = this.parentAnnotation.getPathFromRootAnnotation_();
			path.add(this.pathSegment);
			return path;
		}

	}

	@Override
	public String toString() {
		return annotation == null ? null : annotation.toString();
	}

	/**
	 * @param annotation see {@link #annotation}
	 * @param pathSegment see {@link #pathSegment}
	 * @param parentAnnotation see {@link #parentAnnotation}
	 * @param annotatedElement see {@link #annotatedElement}
	 */
	public AnnotationAndParent(final AnnotationMirror annotation, final Path.Segment pathSegment,
			final AnnotationAndParent parentAnnotation, final Element annotatedElement) {
		super();
		this.annotation = annotation;
		this.pathSegment = pathSegment;
		this.parentAnnotation = parentAnnotation;
		this.annotatedElement = annotatedElement;
	}

	/**
	 * @return see {@link #annotation}.
	 */
	@Override
	public AnnotationMirror getAnnotation() {
		return this.annotation;
	}

	/**
	 * @return see {@link #pathSegment}
	 */
	public Path.Segment getPathSegment() {
		return this.pathSegment;
	}

	/**
	 * @return see {@link #parentAnnotation}
	 */
	public AnnotationAndParent getParentAnnotation() {
		return this.parentAnnotation;
	}

	/**
	 * @return see {@link #annotatedElement}
	 */
	public Element getAnnotatedElement() {
		return this.annotatedElement;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((this.annotation == null) ? 0 : this.annotation.hashCode());
		result = prime * result + ((this.pathSegment == null) ? 0 : this.pathSegment.hashCode());
		result = prime * result + ((this.parentAnnotation == null) ? 0 : this.parentAnnotation.hashCode());
		return prime * result + ((this.annotatedElement == null) ? 0 : this.annotatedElement.hashCode());
	}

	@Override
	public boolean equals(final Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		AnnotationAndParent other = (AnnotationAndParent) obj;
		if (this.annotation == null) {
			if (other.annotation != null)
				return false;
		} else if (!this.annotation.equals(other.annotation))
			return false;
		if (this.pathSegment == null) {
			if (other.pathSegment != null)
				return false;
		} else if (!this.pathSegment.equals(other.pathSegment))
			return false;
		if (this.parentAnnotation == null) {
			if (other.parentAnnotation != null)
				return false;
		} else if (!this.parentAnnotation.equals(other.parentAnnotation))
			return false;
		if (this.annotatedElement == null) {
			if (other.annotatedElement != null)
				return false;
		} else if (!this.annotatedElement.equals(other.annotatedElement))
			return false;
		return true;
	}

}
