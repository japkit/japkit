package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.TypeElement;

/**
 * A generated annotation type (a class that defines an annotation).
 * 
 * @author stefan
 */
public class GenAnnotationType extends GenTypeElement implements TypeElement {
	/**
	 * @param name the simple name of the annotation type.
	 * @param packageName the qualified name of the package of the annotation
	 *            type.
	 */
	public GenAnnotationType(final String name, final String packageName) {
		super(name, packageName);
	}

	/**
	 * @param name the simple name of the annotation type.
	 * @param enclosingElement the enclosing element for the annotation type.
	 *            Typically, a package. Can also be another TypeElement to
	 *            generate the annotation type as inner class.
	 */
	public GenAnnotationType(final String name, final Element enclosingElement) {
		super(name, enclosingElement);
	}

	@Override
	public ElementKind getKind() {
		return ElementKind.ANNOTATION_TYPE;
	}
}
