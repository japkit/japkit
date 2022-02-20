package de.japkit.model;

import static java.util.Arrays.asList;
import static java.util.Collections.unmodifiableList;
import static java.util.Collections.unmodifiableSet;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ElementVisitor;
import javax.lang.model.element.Modifier;
import javax.lang.model.element.Name;
import javax.lang.model.type.TypeMirror;

public abstract class GenElement extends GenAnnotatedConstruct implements Element {

	public static final Set<Modifier> VISIBILITY_MODIFIERS = new HashSet<>(asList(Modifier.PUBLIC, Modifier.PRIVATE, Modifier.PROTECTED));

	/**
	 * The simple name of the element.
	 */
	private Name simpleName;

	/**
	 * The enclosed elements, for instance, the members of a class. See
	 * {@link #getEnclosedElements()}.
	 */
	private List<GenElement> enclosedElements = new ArrayList<>();

	/**
	 * The enclosing elements, for example the class of which this element is a
	 * member. See {@link #getEnclosingElement()}.
	 */
	private Element enclosingElement;

	/**
	 * The modifiers. See {@link #getModifiers()}.
	 */
	private Set<Modifier> modifiers = new HashSet<>();

	/**
	 * The (javadoc-)comment for this element.
	 */
	private CharSequence comment;

	public GenElement() {
	}

	/**
	 * @param simpleName the simple name of the element.
	 */
	public GenElement(final Name simpleName) {
		this.simpleName = simpleName;
	}

	/**
	 * @param simpleName the simple name of the element.
	 */
	public GenElement(final String simpleName) {
		this(new GenName(simpleName));
	}

	@Override
	public <R extends Object, P extends Object> R accept(final ElementVisitor<R, P> v, final P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub");
	}

	@Override
	public TypeMirror asType() {
		throw new UnsupportedOperationException(("asType() is not supported for " + this));
	}

	/**
	 * @return the next enclosing Parameterizable or null if there is none.
	 */
	protected GenParameterizable enclosingParameterizable() {
		if (enclosingElement == null) {
			return null;
		}
		return enclosingElement instanceof GenParameterizable ? (GenParameterizable) enclosingElement
				: ((GenElement) enclosingElement).enclosingParameterizable();
	}

	public CharSequence getComment() {
		return this.comment;
	}

	@Override
	public List<? extends GenElement> getEnclosedElements() {
		return unmodifiableList(enclosedElements);
	}

	@Override
	public Element getEnclosingElement() {
		return enclosingElement;
	}

	@Override
	public abstract ElementKind getKind();

	@Override
	public Set<Modifier> getModifiers() {
		return unmodifiableSet(modifiers);
	}

	@Override
	public Name getSimpleName() {
		return simpleName;
	}

	public void removeModifier(final Modifier aModifier) {
		this.modifiers.remove(aModifier);
	}

	public CharSequence setComment(final CharSequence comment) {
		return this.comment = comment;
	}

	public void setEnclosedElements(final List<? extends GenElement> enclosedElements) {
		this.enclosedElements.clear();
		enclosedElements.forEach(e -> addEnclosedElement(e));
	}

	public void setEnclosingElement(final Element enclosingElement) {
		this.enclosingElement = enclosingElement;
	}

	/**
	 * Adds the given elements as enclosed elements to this.
	 * 
	 * @param elements the enclosed elements to add.
	 */
	public void add(final GenElement... elements) {
		asList(elements).forEach(this::addEnclosedElement);
	}

	/**
	 * Adds an enclosed element at the position determined by
	 * {@link #enclosedElementComparator()}. The back-reference to the enclosing
	 * element is also set.
	 * 
	 * @param enclosedEl the enclosed element to be added.
	 */
	protected void addEnclosedElement(final GenElement enclosedEl) {
		if (!(enclosedEl instanceof GenElement)) {
			throw new IllegalArgumentException(("Only GenElements might be added to a GenElement, but not " + enclosedEl));
		}
		final GenElement enclosed = (enclosedEl);
		if ((enclosed.getEnclosingElement() != null && enclosed.getEnclosingElement() != this)) {
			throw new IllegalStateException(
					"Element " + enclosed + " has already a different enclosing element: " + enclosed.getEnclosingElement());
		}
		Comparator<Element> enclosedElementComparator = enclosedElementComparator();

		if (enclosedElementComparator == null) {
			enclosedElements.add(enclosed);
		} else {
			int index = findInsertionPoint(enclosed, enclosedElementComparator);
			enclosedElements.add(index, enclosed);
		}
		enclosed.setEnclosingElement(this);
	}

	private int findInsertionPoint(final GenElement enclosed, Comparator<Element> enclosedElementComparator) {
		int index = Collections.binarySearch(enclosedElements, enclosed, enclosedElementComparator);
		if ((index < 0)) {
			// "the index of the search key, if it is contained in the
			// list;otherwise, (-(insertion point) - 1)."
			index = (-(index + 1));
		}
		// If there are "equal" elements in the list, insert the new one
		// after them
		while (((index < enclosedElements.size()) && (enclosedElementComparator().compare(enclosed, enclosedElements.get(index)) == 0))) {
			index = (index + 1);
		}
		return index;
	}

	/**
	 * Resolves the type variables of this element in the context of the given
	 * ParameterizableElement
	 */
	protected void resolveContainedTypeVariables(final GenParameterizable parameterizable) {
	}

	/**
	 * @return the order to be enforced for enclosed members. By default, this
	 *         is null which means insertion order.
	 */
	protected Comparator<Element> enclosedElementComparator() {
		return null;
	}

	public void setModifiers(final Set<Modifier> modifiers) {
		this.modifiers.clear();
		for (Modifier aModifier : modifiers) {
			addModifier(aModifier);
		}
	}

	public void addModifier(final Modifier aModifier) {
		this.modifiers.add(aModifier);
	}

	public void setSimpleName(final CharSequence name) {
		this.simpleName = new GenName(name.toString());
	}

	/**
	 * Sets the visibility. Null means default access.
	 * 
	 * @param visibility the visibility modifier. Must be one of
	 *            {@link #VISIBILITY_MODIFIERS} or null for package private
	 *            visibility.
	 */
	public void setVisibility(final Modifier visibility) {
		if ((visibility != null) && (!VISIBILITY_MODIFIERS.contains(visibility))) {
			throw new IllegalArgumentException(visibility + " is not a valid visibility modifier");
		}
		this.modifiers.removeAll(VISIBILITY_MODIFIERS);

		if ((visibility != null)) {
			this.modifiers.add(visibility);
		}
	}

}
