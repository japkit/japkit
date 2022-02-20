package de.japkit.model;

import javax.lang.model.element.Name;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeMirror;

import org.eclipse.xtend2.lib.StringConcatenation;

public abstract class GenVariableElement extends GenElement implements VariableElement {

	private TypeMirror type;

	private Object constantValue;

	@Override
	public TypeMirror asType() {
		return this.type;
	}

	public void setType(final TypeMirror type) {
		this.type = type;
	}

	@Override
	public void resolveContainedTypeVariables(final GenParameterizable parameterizable) {
		this.type = parameterizable.resolveTypeVariables(this.type);
	}

	@Override
	public String toString() {
		StringConcatenation _builder = new StringConcatenation();
		_builder.append(this.type);
		_builder.append(" ");
		Name _simpleName = this.getSimpleName();
		_builder.append(_simpleName);
		return _builder.toString();
	}

	@Override
	public Object getConstantValue() {
		return constantValue;
	}

	public void setConstantValue(final Object constantValue) {
		this.constantValue = constantValue;
	}

	public GenVariableElement(final TypeMirror type) {
		super();
		this.type = type;
	}

	public GenVariableElement(final Name simpleName, final TypeMirror type) {
		super(simpleName);
		this.type = type;
	}

	public GenVariableElement(final String simpleName, final TypeMirror type) {
		super(simpleName);
		this.type = type;
	}
}
