package de.japkit.model;

import java.util.HashMap;
import java.util.Map;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.type.DeclaredType;

/**
 * Sometimes a (meta-)annotation is used many times within a template and some
 * of its values are always the same. For such cases, japkit allows for some
 * rules to define a default annotation to hold those common values. This class
 * comprises the annotation and its according default annotation.
 * <p>
 * Note that the default values from the annotation declaration are not
 * considered here (in accordance with the specification of
 * {@link #getElementValues()}).
 * 
 * @author stefan
 */
public class AnnotationWithDefaultAnnotation implements AnnotationMirror {
	/**
	 * The annotation.
	 */
	private final AnnotationMirror annotation;

	/**
	 * The default annotation that defines defaults for values of
	 * {@link #annotation}, as long as they are not defined there.
	 */
	private final AnnotationMirror defaultAnnotation;

	@Override
	public DeclaredType getAnnotationType() {
		return this.annotation.getAnnotationType();
	}

	@Override
	public Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValues() {
		final Map<ExecutableElement, AnnotationValue> result = new HashMap<>(defaultAnnotation.getElementValues());
		result.putAll(this.annotation.getElementValues());
		return result;
	}

	/**
	 * Creates an AnnotationWithDefaultAnnotation if and only if annotation and
	 * defaultAnnotation are not null. Otherwise it returns the one of both
	 * which is not null.
	 * 
	 * @param annotation see {@link #annotation}
	 * @param defaultAnnotation see {@link #defaultAnnotation}
	 * @return the AnnotationWithDefaultAnnotation or the annotation or the
	 *         defaultAnnotation or null
	 */
	public static AnnotationMirror createIfNecessary(final AnnotationMirror annotation, final AnnotationMirror defaultAnnotation) {
		return annotation == null ? defaultAnnotation
				: (defaultAnnotation == null ? annotation : new AnnotationWithDefaultAnnotation(annotation, defaultAnnotation));

	}

	/**
	 * @param annotation see {@link #annotation}
	 * @param defaultAnnotation see {@link #defaultAnnotation}
	 */
	private AnnotationWithDefaultAnnotation(final AnnotationMirror annotation, final AnnotationMirror defaultAnnotation) {
		this.annotation = annotation;
		this.defaultAnnotation = defaultAnnotation;
	}

	/**
	 * @return see {@link #annotation}
	 */
	public AnnotationMirror getAnnotation() {
		return this.annotation;
	}

	/**
	 * @return see {@link #defaultAnnotation}
	 */
	public AnnotationMirror getDefaultAnnotation() {
		return this.defaultAnnotation;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((this.annotation == null) ? 0 : this.annotation.hashCode());
		return prime * result + ((this.defaultAnnotation == null) ? 0 : this.defaultAnnotation.hashCode());
	}

	@Override
	public boolean equals(final Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		AnnotationWithDefaultAnnotation other = (AnnotationWithDefaultAnnotation) obj;
		if (this.annotation == null) {
			if (other.annotation != null)
				return false;
		} else if (!this.annotation.equals(other.annotation))
			return false;
		if (this.defaultAnnotation == null) {
			if (other.defaultAnnotation != null)
				return false;
		} else if (!this.defaultAnnotation.equals(other.defaultAnnotation))
			return false;
		return true;
	}

	@Override
	public String toString() {
		return "AnnotationWithDefaultAnnotation [annotation=" + annotation + ", defaultAnnotation=" + defaultAnnotation + "]";
	}

}
