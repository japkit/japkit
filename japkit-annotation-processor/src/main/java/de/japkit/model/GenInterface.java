package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeElement;

public class GenInterface extends GenTypeElement implements TypeElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.INTERFACE;
	}

	public GenInterface(final String name, final String packageName) {
		super(name, packageName);
	}

	public GenInterface(final String name, final Element enclosingElement) {
		super(name, enclosingElement);
	}

	public GenInterface(final String name) {
		super(name);
	}

	public GenInterface(final Name name) {
		super(name);
	}

	public GenInterface() {
		super();
	}
}
