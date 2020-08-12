package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeMirror;

public class GenField extends GenVariableElement implements VariableElement {
	private CodeBody constantExpr;

	public CodeBody getConstantExpr() {
		return this.constantExpr;
	}

	public CodeBody setConstantExpr(final CodeBody constantExpr) {
		return this.constantExpr = constantExpr;
	}

	@Override
	public ElementKind getKind() {
		return ElementKind.FIELD;
	}

	public GenField(final TypeMirror type) {
		super(type);
	}

	public GenField(final Name simpleName, final TypeMirror type) {
		super(simpleName, type);
	}

	public GenField(final String simpleName, final TypeMirror type) {
		super(simpleName, type);
	}
}
