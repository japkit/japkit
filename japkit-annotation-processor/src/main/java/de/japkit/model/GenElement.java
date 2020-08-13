package de.japkit.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Consumer;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ElementVisitor;
import javax.lang.model.element.Modifier;
import javax.lang.model.element.Name;
import javax.lang.model.type.TypeMirror;

import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Conversions;

import com.google.common.base.Objects;

import de.japkit.services.ElementsExtensions;

public abstract class GenElement extends GenAnnotatedConstruct implements Element {
	private Name simpleName;

	private List<Element> enclosedElements = new ArrayList<>();

	private Element enclosingElement;

	private Set<Modifier> modifiers = new HashSet<>();

	private CharSequence comment;

	@Override
	public <R extends Object, P extends Object> R accept(final ElementVisitor<R, P> v, final P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub");
	}

	@Override
	public TypeMirror asType() {
		throw new UnsupportedOperationException(("asType() is not supported for " + this));
	}

	@Override
	public abstract ElementKind getKind();

	public void addEnclosedElement(final Element enclosedEl) {
		if ((!(enclosedEl instanceof GenElement))) {
			throw new IllegalArgumentException(("Only GenElements might be added to a GenElement, but not " + enclosedEl));
		}
		final GenElement enclosed = ((GenElement) enclosedEl);
		if (((enclosed.getEnclosingElement() != null) && (!Objects.equal(enclosed.getEnclosingElement(), this)))) {
			StringConcatenation _builder = new StringConcatenation();
			_builder.append("Element ");
			_builder.append(enclosed);
			_builder.append(" has already a different enclosing element:");
			Element _enclosingElement = enclosed.getEnclosingElement();
			_builder.append(_enclosingElement);
			throw new IllegalStateException(_builder.toString());
		}
		Comparator<Element> _enclosedElementComparator = this.enclosedElementComparator();
		boolean _tripleEquals = (_enclosedElementComparator == null);
		if (_tripleEquals) {
			this.enclosedElements.add(enclosed);
		} else {
			int index = Collections.<Element> binarySearch(this.enclosedElements, enclosed, this.enclosedElementComparator());
			if ((index < 0)) {
				index = (-(index + 1));
			}
			while (((index < this.enclosedElements.size())
					&& (this.enclosedElementComparator().compare(enclosed, this.enclosedElements.get(index)) == 0))) {
				index = (index + 1);
			}
			this.enclosedElements.add(index, enclosed);
		}
		enclosed.setEnclosingElement(this);
	}

	public Comparator<Element> enclosedElementComparator() {
		return null;
	}

	public void add(final GenElement... elements) {
		final Consumer<GenElement> _function = (GenElement e) -> {
			this.addEnclosedElement(e);
		};
		((List<GenElement>) Conversions.doWrapArray(elements)).forEach(_function);
	}

	public GenParameterizable enclosingParameterizable() {
		GenParameterizable _xifexpression = null;
		if ((this.enclosingElement == null)) {
			_xifexpression = null;
		} else {
			GenParameterizable _xifexpression_1 = null;
			if ((this.enclosingElement instanceof GenParameterizable)) {
				_xifexpression_1 = ((GenParameterizable) this.enclosingElement);
			} else {
				_xifexpression_1 = ((GenElement) this.enclosingElement).enclosingParameterizable();
			}
			_xifexpression = _xifexpression_1;
		}
		return _xifexpression;
	}

	/**
	 * Sets the visibility. Null means default access.
	 */
	public boolean setVisibility(final Modifier visibility) {
		boolean _xblockexpression = false;
		{
			if (((visibility != null) && (!ElementsExtensions.VISIBILITY_MODIFIERS.contains(visibility)))) {
				StringConcatenation _builder = new StringConcatenation();
				_builder.append(visibility);
				_builder.append(" is not a valid visibility modifier");
				throw new IllegalArgumentException(_builder.toString());
			}
			this.modifiers.removeAll(ElementsExtensions.VISIBILITY_MODIFIERS);
			boolean _xifexpression = false;
			if ((visibility != null)) {
				_xifexpression = this.modifiers.add(visibility);
			}
			_xblockexpression = _xifexpression;
		}
		return _xblockexpression;
	}

	/**
	 * Resolves the type variables of this element in the context of the given
	 * ParameterizableElement
	 */
	public void resolveContainedTypeVariables(final GenParameterizable parameterizable) {
	}

	public CharSequence getComment() {
		return this.comment;
	}

	public CharSequence setComment(final CharSequence comment) {
		return this.comment = comment;
	}

	public Name setSimpleName(final CharSequence name) {
		String _string = name.toString();
		GenName _genName = new GenName(_string);
		return this.simpleName = _genName;
	}

	public GenElement() {
	}

	public GenElement(final Name simpleName) {
		this.simpleName = simpleName;
	}

	public GenElement(final String simpleName) {
		this(new GenName(simpleName));
	}

	@Override
	public List<? extends Element> getEnclosedElements() {
		return java.util.Collections.unmodifiableList(enclosedElements);
	}

	public void removeEnclosedElement(final Element aEnclosedElement_) {
		this.enclosedElements.remove(aEnclosedElement_);
	}

	public void setEnclosedElements(final List<? extends Element> enclosedElements) {
		this.enclosedElements.clear();
		for (Element aEnclosedElement_ : enclosedElements) {
			addEnclosedElement(aEnclosedElement_);
		}
	}

	@Override
	public Element getEnclosingElement() {
		return enclosingElement;
	}

	public void setEnclosingElement(final Element enclosingElement) {
		this.enclosingElement = enclosingElement;
	}

	@Override
	public Set<Modifier> getModifiers() {
		return java.util.Collections.unmodifiableSet(modifiers);
	}

	public void addModifier(final Modifier aModifier_) {
		this.modifiers.add(aModifier_);
	}

	public void removeModifier(final Modifier aModifier_) {
		this.modifiers.remove(aModifier_);
	}

	public void setModifiers(final Set<Modifier> modifiers) {
		this.modifiers.clear();
		for (Modifier aModifier_ : modifiers) {
			addModifier(aModifier_);
		}
	}

	@Override
	public Name getSimpleName() {
		return simpleName;
	}

	public void setSimpleName(final Name simpleName) {
		this.simpleName = simpleName;
	}
}
