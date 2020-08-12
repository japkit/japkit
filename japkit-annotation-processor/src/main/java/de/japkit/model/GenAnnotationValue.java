package de.japkit.model;

import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.AnnotationValueVisitor;

public class GenAnnotationValue implements AnnotationValue {
	private Object value;

	@Override
	public <R extends Object, P extends Object> R accept(final AnnotationValueVisitor<R, P> v, final P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub");
	}

	@Override
	public Object getValue() {
		return value;
	}

	public void setValue(final Object value) {
		this.value = value;
	}

	public GenAnnotationValue(final Object value) {
		super();
		this.value = value;
	}
}
