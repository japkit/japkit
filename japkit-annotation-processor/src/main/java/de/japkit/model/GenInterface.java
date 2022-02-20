package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeElement;
import javax.lang.model.type.TypeMirror;

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

	@Override
	public TypeMirror getSuperclass() {
		// TODO According to the spec, we have to return a NoType here.
		return super.getSuperclass();
	}
}
