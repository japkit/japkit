package de.japkit.model;

import java.util.ArrayList;
import java.util.List;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeParameterElement;
import javax.lang.model.type.TypeMirror;

public class GenTypeParameter extends GenElement implements TypeParameterElement {
	public static final ElementKind kind = ElementKind.TYPE_PARAMETER;

	private TypeMirror typeVariable;

	private List<TypeMirror> bounds = new ArrayList<>();

	private Element genericElement;

	@Override
	public Element getEnclosingElement() {
		return this.genericElement;
	}

	@Override
	public void setEnclosingElement(final Element e) {
		this.genericElement = e;
	}

	/**
	 * Copy-Constructor.
	 */
	public GenTypeParameter(final TypeParameterElement original, final Element genericEl) {
		this(original.getSimpleName());
		this.bounds.addAll(original.getBounds());
		this.genericElement = genericEl;
		this.typeVariable = original.asType();
	}

	@Override
	public TypeMirror asType() {
		return this.typeVariable;
	}

	@Override
	public List<? extends TypeMirror> getBounds() {
		return java.util.Collections.unmodifiableList(bounds);
	}

	public void addBound(final TypeMirror aBound_) {
		this.bounds.add(aBound_);
	}

	public void removeBound(final TypeMirror aBound_) {
		this.bounds.remove(aBound_);
	}

	public void setBounds(final List<? extends TypeMirror> bounds) {
		this.bounds.clear();
		for (TypeMirror aBound_ : bounds) {
			addBound(aBound_);
		}
	}

	@Override
	public Element getGenericElement() {
		return genericElement;
	}

	public void setGenericElement(final Element genericElement) {
		this.genericElement = genericElement;
	}

	@Override
	public ElementKind getKind() {
		return kind;
	}

	public GenTypeParameter() {
		super();
	}

	public GenTypeParameter(final Name simpleName) {
		super(simpleName);
	}

	public GenTypeParameter(final String simpleName) {
		super(simpleName);
	}
}
