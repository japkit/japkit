package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeMirror;

public class GenEnumConstant extends GenVariableElement implements VariableElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.ENUM_CONSTANT;
	}

	public GenEnumConstant(final TypeMirror type) {
		super(type);
	}

	public GenEnumConstant(final Name simpleName, final TypeMirror type) {
		super(simpleName, type);
	}

	public GenEnumConstant(final String simpleName, final TypeMirror type) {
		super(simpleName, type);
	}
}
