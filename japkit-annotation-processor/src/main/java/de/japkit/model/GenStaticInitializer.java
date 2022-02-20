package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ExecutableElement;

public class GenStaticInitializer extends GenExecutableElement implements ExecutableElement {
	@Override
	public ElementKind getKind() {
		return ElementKind.STATIC_INIT;
	}

	public GenStaticInitializer() {
		super("<clinit>");
	}
}
