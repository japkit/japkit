package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeElement;

public class GenAnnotationType extends GenTypeElement implements TypeElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.ANNOTATION_TYPE;
	}

	public GenAnnotationType(final String name, final String packageName) {
		super(name, packageName);
	}

	public GenAnnotationType(final String name, final Element enclosingElement) {
		super(name, enclosingElement);
	}

	public GenAnnotationType(final String name) {
		super(name);
	}

	public GenAnnotationType(final Name name) {
		super(name);
	}

	public GenAnnotationType() {
		super();
	}
}
