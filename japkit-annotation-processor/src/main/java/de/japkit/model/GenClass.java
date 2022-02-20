package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeElement;
import javax.lang.model.type.TypeMirror;

import de.japkit.services.ExtensionRegistry;
import de.japkit.services.TypesExtensions;

/**
 * A generated class.
 * 
 * @author stefan
 */
public class GenClass extends GenTypeElement implements TypeElement {

	public GenClass(final Name name) {
		super(name);
	}

	public GenClass(final String name) {
		super(name);
	}

	/**
	 * @param name the simple name of the class.
	 * @param the enclosing element for the annotation type. Must be a package
	 *            or another TypeElement to generate an inner class.
	 */
	public GenClass(final String name, final Element enclosingElement) {
		super(name, enclosingElement);
	}

	/**
	 * @param name the simple name of the class.
	 * @param packageName the qualified name of the package of the class.
	 */
	public GenClass(final String name, final String packageName) {
		super(name, packageName);
	}

	@Override
	public ElementKind getKind() {
		return ElementKind.CLASS;
	}

	@Override
	public TypeMirror getSuperclass() {
		TypeMirror superclass = super.getSuperclass();
		return superclass != null ? superclass : ExtensionRegistry.get(TypesExtensions.class).getJavaLangObject();
	}
}
