package de.japkit.model;

import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.AnnotationValueVisitor;

/**
 * A generated annotation value.
 * 
 * @author stefan
 */
public class GenAnnotationValue implements AnnotationValue {
	/**
	 * The annotation value. For possible values see {@link AnnotationValue}.
	 */
	private Object value;

	/**
	 * @param value see {@link #value}
	 */
	public GenAnnotationValue(final Object value) {
		super();
		this.value = value;
	}

	@Override
	public Object getValue() {
		return value;
	}

	@Override
	public <R extends Object, P extends Object> R accept(final AnnotationValueVisitor<R, P> v, final P p) {
		throw new UnsupportedOperationException("Not supported.");
	}
}
