package de.japkit.model;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Function;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeMirror;

import de.japkit.services.ElementsExtensions;
import de.japkit.services.ExtensionRegistry;

public class GenAnnotationMirror implements AnnotationMirror {

	private ElementsExtensions _elementsExtensions = ExtensionRegistry.get(ElementsExtensions.class);

	/**
	 * The type of the annotation.
	 */
	private DeclaredType annotationType;

	/**
	 * The annotation values. The keys are the according AV methods from
	 * {@link #annotationType}.
	 */
	private Map<ExecutableElement, GenAnnotationValue> elementValues = new LinkedHashMap<>();

	/**
	 * @param annotationType see {@link #annotationType}.
	 */
	public GenAnnotationMirror(final DeclaredType annotationType) {
		super();
		this.annotationType = annotationType;
	}

	@Override
	public DeclaredType getAnnotationType() {
		return annotationType;
	}

	@Override
	public Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValues() {
		return elementValues;
	}

	/**
	 * Gets an annotation value as explicitly present in the annotation. Default
	 * values from the annotation's definition are not considered.
	 * 
	 * @param name the name of the annotation value
	 * @return the annotation value or null if not present in the annotation
	 */
	public GenAnnotationValue getValueWithoutDefault(final String name) {
		return elementValues.get(this.getAVMethod(name, true));
	}

	/**
	 * Sets an annotation value. The required type for the annotation value is
	 * provided as argument to a value factory.
	 * 
	 * @param name the name of the annotation value
	 * @param valueFactory the factory which provides the value. The value may
	 *            be null to remove the annotation value.
	 */
	public void setValue(final String name, final Function<? super TypeMirror, ? extends GenAnnotationValue> valueFactory) {
		final ExecutableElement avMethod = getAVMethod(name, true);
		final GenAnnotationValue v = valueFactory.apply(avMethod.getReturnType());
		setValueInternal(avMethod, v);
	}

	/**
	 * Sets an annotation value.
	 * 
	 * @param name the name of the annotation value
	 * @param v the value. The value may be null to remove the annotation value.
	 */
	public void setValue(final String name, final GenAnnotationValue v) {
		final ExecutableElement avMethod = getAVMethod(name, true);
		setValueInternal(avMethod, v);
	}

	private void setValueInternal(final ExecutableElement exEl, final GenAnnotationValue v) {
		if (v == null) {
			elementValues.remove(exEl);
		} else {
			elementValues.put(exEl, v);
		}
	}

	/**
	 * Gets the according method in the annotation's definition for an
	 * annotation value.
	 * 
	 * @param name the name of the annotation value
	 * @param required true means that an exception is thrown if the method is
	 *            not found
	 * @return the method or null
	 */
	public ExecutableElement getAVMethod(final String name, final boolean required) {
		ExecutableElement avMethod = this._elementsExtensions.getAVMethod(this, name);
		if (avMethod != null) {
			return avMethod;
		}
		if (required) {
			throw new IllegalArgumentException("Annotation value \'" + name + "\' is not defined in annotation type "
					+ this._elementsExtensions.annotationAsTypeElement(this).getQualifiedName());
		}
		return null;
	}
}
