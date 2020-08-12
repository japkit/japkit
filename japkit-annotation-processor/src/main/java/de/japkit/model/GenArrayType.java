package de.japkit.model;

import javax.lang.model.type.ArrayType;
import javax.lang.model.type.TypeKind;
import javax.lang.model.type.TypeMirror;
import javax.lang.model.type.TypeVisitor;

import org.eclipse.xtend2.lib.StringConcatenation;

@SuppressWarnings("all")
public class GenArrayType extends GenTypeMirror implements ArrayType {
	private TypeMirror componentType;

	@Override
	public String toString() {
		StringConcatenation _builder = new StringConcatenation();
		_builder.append(this.componentType);
		_builder.append(" []");
		return _builder.toString();
	}

	@Override
	public <R extends Object, P extends Object> R accept(final TypeVisitor<R, P> v, final P p) {
		return v.visitArray(this, p);
	}

	@Override
	public TypeMirror getComponentType() {
		return componentType;
	}

	public void setComponentType(final TypeMirror componentType) {
		this.componentType = componentType;
	}

	@Override
	public TypeKind getKind() {
		return TypeKind.ARRAY;
	}

	public GenArrayType(final TypeMirror componentType) {
		super();
		this.componentType = componentType;
	}
}
