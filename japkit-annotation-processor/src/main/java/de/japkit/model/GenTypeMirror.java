package de.japkit.model;

import javax.lang.model.type.TypeKind;
import javax.lang.model.type.TypeMirror;

public abstract class GenTypeMirror extends GenAnnotatedConstruct implements TypeMirror {
	@Override
	public abstract TypeKind getKind();

	public GenTypeMirror() {
		super();
	}
}
