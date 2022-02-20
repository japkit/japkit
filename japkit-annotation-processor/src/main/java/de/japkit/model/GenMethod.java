package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.Name;

public class GenMethod extends GenExecutableElement implements ExecutableElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.METHOD;
	}

	public GenMethod(final String simpleName) {
		super(simpleName);
	}

	public GenMethod(final Name simpleName) {
		super(simpleName);
	}

	public GenMethod() {
		super();
	}
}
