package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ExecutableElement;

public class GenConstructor extends GenExecutableElement implements ExecutableElement {
	public static final ElementKind kind = ElementKind.CONSTRUCTOR;

	public static final String simpleName_default = "<init>";

	@Override
	public ElementKind getKind() {
		return kind;
	}

	public GenConstructor() {
		super(simpleName_default);
	}
}
