package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeMirror;

public class GenParameter extends GenVariableElement implements VariableElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.PARAMETER;
	}

	public GenParameter(final TypeMirror type) {
		super(type);
	}

	public GenParameter(final Name simpleName, final TypeMirror type) {
		super(simpleName, type);
	}

	public GenParameter(final String simpleName, final TypeMirror type) {
		super(simpleName, type);
	}
}
