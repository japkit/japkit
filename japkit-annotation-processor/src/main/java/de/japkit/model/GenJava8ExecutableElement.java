package de.japkit.model;

import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.Name;
import javax.lang.model.type.TypeMirror;

public abstract class GenJava8ExecutableElement extends GenParameterizable implements ExecutableElement {

	
	
	public GenJava8ExecutableElement() {
		super();
	}

	public GenJava8ExecutableElement(Name simpleName) {
		super(simpleName);
	}

	public GenJava8ExecutableElement(String simpleName) {
		super(simpleName);
	}

	public TypeMirror getReceiverType() {
		throw new UnsupportedOperationException();
	}

	public boolean isDefault() {
		throw new UnsupportedOperationException();
	}

}
