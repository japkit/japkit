package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ExecutableElement;

public class GenInitializer extends GenExecutableElement implements ExecutableElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.INSTANCE_INIT;
	}

	public GenInitializer() {
		super("");
	}
}
