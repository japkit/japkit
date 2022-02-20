package de.japkit.model;

import javax.lang.model.type.ArrayType;
import javax.lang.model.type.TypeKind;
import javax.lang.model.type.TypeMirror;
import javax.lang.model.type.TypeVisitor;

/**
 * A generated array type.
 * 
 * @author stefan
 */
public class GenArrayType extends GenTypeMirror implements ArrayType {
	/**
	 * The type of the array elements.
	 */
	private TypeMirror componentType;

	/**
	 * @param componentType see {@link #componentType}
	 */
	public GenArrayType(final TypeMirror componentType) {
		this.componentType = componentType;
	}

	@Override
	public <R extends Object, P extends Object> R accept(final TypeVisitor<R, P> v, final P p) {
		return v.visitArray(this, p);
	}

	@Override
	public TypeMirror getComponentType() {
		return componentType;
	}

	@Override
	public TypeKind getKind() {
		return TypeKind.ARRAY;
	}

	@Override
	public String toString() {
		return componentType + " []";
	}
}
