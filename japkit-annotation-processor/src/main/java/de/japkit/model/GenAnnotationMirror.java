package de.japkit.model;

import java.util.Map;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.Name;
import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeMirror;

import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Extension;
import org.eclipse.xtext.xbase.lib.Functions.Function1;

import de.japkit.services.ElementsExtensions;
import de.japkit.services.ExtensionRegistry;

public class GenAnnotationMirror implements AnnotationMirror {
	@Extension
	protected ElementsExtensions _elementsExtensions = ExtensionRegistry.<ElementsExtensions> get(ElementsExtensions.class);

	private DeclaredType annotationType;

	private Map<ExecutableElement, GenAnnotationValue> elementValues = CollectionLiterals.newLinkedHashMap();

	public GenAnnotationValue setValue(final String name, final Function1<? super TypeMirror, ? extends GenAnnotationValue> valueFactory) {
		GenAnnotationValue _xblockexpression = null;
		{
			final ExecutableElement exEl = this.getAVMethod(name, true);
			final GenAnnotationValue v = valueFactory.apply(exEl.getReturnType());
			_xblockexpression = this.setValueInternal(exEl, v);
		}
		return _xblockexpression;
	}

	public GenAnnotationValue setValue(final String name, final GenAnnotationValue v) {
		GenAnnotationValue _xblockexpression = null;
		{
			final ExecutableElement exEl = this.getAVMethod(name, true);
			_xblockexpression = this.setValueInternal(exEl, v);
		}
		return _xblockexpression;
	}

	/**
	 * Test
	 */
	private GenAnnotationValue setValueInternal(final ExecutableElement exEl, final GenAnnotationValue v) {
		GenAnnotationValue _xifexpression = null;
		if ((v == null)) {
			_xifexpression = this.elementValues.remove(exEl);
		} else {
			_xifexpression = this.elementValues.put(exEl, v);
		}
		return _xifexpression;
	}

	public GenAnnotationValue getValueWithoutDefault(final String name) {
		GenAnnotationValue _xblockexpression = null;
		{
			final ExecutableElement exEl = this.getAVMethod(name, true);
			_xblockexpression = this.elementValues.get(exEl);
		}
		return _xblockexpression;
	}

	public ExecutableElement getAVMethod(final String name, final boolean required) {
		ExecutableElement _elvis = null;
		ExecutableElement _aVMethod = this._elementsExtensions.getAVMethod(this, name);
		if (_aVMethod != null) {
			_elvis = _aVMethod;
		} else {
			Object _xifexpression = null;
			if (required) {
				StringConcatenation _builder = new StringConcatenation();
				_builder.append("Annotation value \'");
				_builder.append(name);
				_builder.append("\' is not defined in annotation type ");
				Name _qualifiedName = this._elementsExtensions.annotationAsTypeElement(this).getQualifiedName();
				_builder.append(_qualifiedName);
				throw new IllegalArgumentException(_builder.toString());
			} else {
				_xifexpression = null;
			}
			_elvis = ((ExecutableElement) _xifexpression);
		}
		return _elvis;
	}

	public void setElementValues(final Map<? extends ExecutableElement, ? extends AnnotationValue> elementValues) {
		throw new UnsupportedOperationException("Please use setValue instead");
	}

	@Override
	public DeclaredType getAnnotationType() {
		return annotationType;
	}

	public void setAnnotationType(final DeclaredType annotationType) {
		this.annotationType = annotationType;
	}

	@Override
	public Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValues() {
		return elementValues;
	}

	public GenAnnotationMirror(final DeclaredType annotationType) {
		super();
		this.annotationType = annotationType;
	}
}
