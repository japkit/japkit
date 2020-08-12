package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeElement;

public class GenEnum extends GenTypeElement implements TypeElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.ENUM;
	}

	public GenEnum(final String name, final String packageName) {
		super(name, packageName);
	}

	public GenEnum(final String name, final Element enclosingElement) {
		super(name, enclosingElement);
	}

	public GenEnum(final String name) {
		super(name);
	}

	public GenEnum(final Name name) {
		super(name);
	}

	public GenEnum() {
		super();
	}
}
