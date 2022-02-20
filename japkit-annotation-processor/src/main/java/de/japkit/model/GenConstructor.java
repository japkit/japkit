package de.japkit.model;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ExecutableElement;

/**
 * A generated constructor.
 * 
 * @author stefan
 */
public class GenConstructor extends GenExecutableElement implements ExecutableElement {
	public GenConstructor() {
		super("<init>");
	}

	@Override
	public ElementKind getKind() {
		return ElementKind.CONSTRUCTOR;
	}
}
