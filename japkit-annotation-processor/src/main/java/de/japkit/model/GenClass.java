package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeElement;
import javax.lang.model.type.TypeMirror;

import de.japkit.services.ExtensionRegistry;
import de.japkit.services.TypesExtensions;

public class GenClass extends GenTypeElement implements TypeElement {
	@Override
	public TypeMirror getSuperclass() {
		TypeMirror _elvis = null;
		TypeMirror _superclass = super.getSuperclass();
		if (_superclass != null) {
			_elvis = _superclass;
		} else {
			TypeMirror _javaLangObject = ExtensionRegistry.get(TypesExtensions.class).getJavaLangObject();
			_elvis = _javaLangObject;
		}
		return _elvis;
	}

	@Override
	public ElementKind getKind() {
		return ElementKind.CLASS;
	}

	public GenClass(final String name, final String packageName) {
		super(name, packageName);
	}

	public GenClass(final String name, final Element enclosingElement) {
		super(name, enclosingElement);
	}

	public GenClass(final String name) {
		super(name);
	}

	public GenClass(final Name name) {
		super(name);
	}

	public GenClass() {
		super();
	}
}
