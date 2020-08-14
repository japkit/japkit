package de.japkit.model;

import static java.util.Arrays.asList;
import static java.util.stream.Collectors.toList;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Consumer;
import java.util.stream.IntStream;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.Name;
import javax.lang.model.element.NestingKind;
import javax.lang.model.element.PackageElement;
import javax.lang.model.element.QualifiedNameable;
import javax.lang.model.element.TypeElement;
import javax.lang.model.element.TypeParameterElement;
import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeMirror;
import javax.lang.model.type.TypeVariable;

import org.eclipse.xtend.lib.annotations.Accessors;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.Extension;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.Functions.Function2;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.Pure;

import com.google.common.base.Objects;
import com.google.common.collect.Iterables;

import de.japkit.services.ElementsExtensions;
import de.japkit.services.ExtensionRegistry;
import de.japkit.services.TypesExtensions;

public abstract class GenTypeElement extends GenParameterizable implements TypeElement {
	private List<TypeMirror> interfaces = new ArrayList<>();

	private NestingKind nestingKind;

	private TypeMirror superclass;

	@Accessors
	private Set<GenTypeElement> auxTopLevelClasses = new HashSet<>();

	@Accessors
	private boolean auxClass;

	private Name qualifiedName;

	@Override
	public Name getQualifiedName() {
		return this.qualifiedName;
	}

	public GenTypeElement(final String name, final String packageName) {
		this(name, GenPackage.packageForName(packageName));
	}

	public GenTypeElement(final String name, final Element enclosingElement) {
		super(name);
		this.setEnclosingElement(enclosingElement);
		StringConcatenation _builder = new StringConcatenation();
		Name _qualifiedName = null;
		if (((QualifiedNameable) enclosingElement) != null) {
			_qualifiedName = ((QualifiedNameable) enclosingElement).getQualifiedName();
		}
		_builder.append(_qualifiedName);
		_builder.append(".");
		Name _simpleName = this.getSimpleName();
		_builder.append(_simpleName);
		GenName _genName = new GenName(_builder.toString());
		this.qualifiedName = _genName;
		if ((enclosingElement instanceof PackageElement)) {
			this.setNestingKind(NestingKind.TOP_LEVEL);
		} else {
			if ((enclosingElement instanceof TypeElement)) {
				this.setNestingKind(NestingKind.MEMBER);
			} else {
				throw new IllegalArgumentException(
						("Enclosing element of a class must be a PackageElement or a TypeElement, but not " + enclosingElement));
			}
		}
	}

	@Override
	public void setEnclosingElement(final Element e) {
		super.setEnclosingElement(e);
		StringConcatenation _builder = new StringConcatenation();
		Element _enclosingElement = this.getEnclosingElement();
		Name _qualifiedName = null;
		if (((QualifiedNameable) _enclosingElement) != null) {
			_qualifiedName = ((QualifiedNameable) _enclosingElement).getQualifiedName();
		}
		_builder.append(_qualifiedName);
		_builder.append(".");
		Name _simpleName = this.getSimpleName();
		_builder.append(_simpleName);
		GenName _genName = new GenName(_builder.toString());
		this.qualifiedName = _genName;
	}

	/**
	 * Set the superclass. If the given superclass is generic, the parameter is
	 * expected to be a prototype. The type variables of the prototype will be
	 * replaces by the given type arguments then. The list of type arguments
	 * must match the type variables but is allowed to contain null values. For
	 * each null value, the type element gets a type parameter with the same
	 * name as in the superclass. If there already exists a type parameter with
	 * that name (from some interface), it is reused.
	 * <p>
	 */
	public void setSuperclass(final DeclaredType type, final TypeMirror... typeArgs) {
		if ((type != null)) {
			TypeMirror _asType = type.asElement().asType();
			final DeclaredType superclassPrototype = ((DeclaredType) _asType);
			this.superclass = this.resolveTypeArgs(superclassPrototype, typeArgs);
		} else {
			this.superclass = null;
		}
	}

	public void setSuperclass(final DeclaredType type) {
		TypeMirror[] _elvis = null;
		List<? extends TypeMirror> _typeArguments = null;
		if (type != null) {
			_typeArguments = type.getTypeArguments();
		}
		if (((TypeMirror[]) Conversions.unwrapArray(_typeArguments, TypeMirror.class)) != null) {
			_elvis = ((TypeMirror[]) Conversions.unwrapArray(_typeArguments, TypeMirror.class));
		} else {
			_elvis = null;
		}
		this.setSuperclass(type, _elvis);
	}

	/**
	 * Adds an interface. If the given interface is generic, the parameter is
	 * expected to be a prototype. The type variables of the prototype will be
	 * replaces by the given type arguments then. The list of type arguments
	 * must match the type variables but is allowed to contain null values. For
	 * each null value, the type element gets a type parameter with the same
	 * name as in the interface. If there already exists a type parameter with
	 * that name (from some other interface or from the superclass), it is
	 * reused.
	 */
	public void addInterface(final DeclaredType type, final TypeMirror... typeArgs) {
		TypeMirror _asType = type.asElement().asType();
		final DeclaredType interfacePrototype = ((DeclaredType) _asType);
		this.interfaces.add(this.resolveTypeArgs(interfacePrototype, typeArgs));
	}

	public void addInterface(final TypeMirror type) {
		this.addInterface(((DeclaredType) type),
				((TypeMirror[]) Conversions.unwrapArray(((DeclaredType) type).getTypeArguments(), TypeMirror.class)));
	}

	/**
	 * Copies the type parameters from another type element. A typical use case
	 * is to generate an interface from an existing class.
	 * <p>
	 * TODO: Not all variables are needed in such cases ... TODO: also consider
	 * enclosing types?
	 */
	public void copyTypeParametersFrom(final GenTypeElement other) {
		final Consumer<TypeParameterElement> _function = (TypeParameterElement p) -> {
			final TypeParameterElement ownParam = this.getOrCreateTypeParameter(p);
			this.addTypeParameter(ownParam);
		};
		other.getTypeParameters().forEach(_function);
	}

	/**
	 * How are the type arguments of superclass and interfaces resolved in this
	 * type?
	 */
	private final Map<TypeParameterElement, TypeMirror> resolvedTypeArgsMap = new HashMap<>();

	public Map<TypeParameterElement, TypeMirror> getResolvedTypeArgsMap() {
		return this.resolvedTypeArgsMap;
	}

	public DeclaredType resolveTypeArgs(final DeclaredType prototype, final TypeMirror[] typeArgs) {
		DeclaredType _xblockexpression = null;
		{
			boolean _isNullOrEmpty = IterableExtensions.isNullOrEmpty(prototype.getTypeArguments());
			if (_isNullOrEmpty) {
				return prototype;
			}
			int _size = prototype.getTypeArguments().size();
			final Function1<Integer, TypeMirror> _function = (Integer n) -> {
				TypeMirror _xblockexpression_1 = null;
				{
					TypeMirror _xifexpression = null;
					boolean _isNullOrEmpty_1 = IterableExtensions.isNullOrEmpty(((Iterable<?>) Conversions.doWrapArray(typeArgs)));
					if (_isNullOrEmpty_1) {
						_xifexpression = null;
					} else {
						_xifexpression = typeArgs[(n).intValue()];
					}
					final TypeMirror typeArg = _xifexpression;
					TypeMirror _get = prototype.getTypeArguments().get((n).intValue());
					final TypeVariable typeVariable = ((TypeVariable) _get);
					TypeMirror _xifexpression_1 = null;
					if ((typeArg == null)) {
						TypeVariable _xblockexpression_2 = null;
						{
							Element _asElement = typeVariable.asElement();
							this.addTypeParameter(this.getOrCreateTypeParameter(((TypeParameterElement) _asElement)));
							_xblockexpression_2 = typeVariable;
						}
						_xifexpression_1 = _xblockexpression_2;
					} else {
						_xifexpression_1 = typeArg;
					}
					final TypeMirror resolved = _xifexpression_1;
					Element _asElement = typeVariable.asElement();
					this.resolvedTypeArgsMap.put(((TypeParameterElement) _asElement), resolved);
					_xblockexpression_1 = resolved;
				}
				return _xblockexpression_1;
			};
			final List<TypeMirror> resolvedTypeArgs = IntStream.range(0, _size).mapToObj(_function::apply).collect(toList());
			_xblockexpression = this.getDeclaredType(prototype, resolvedTypeArgs);
		}
		return _xblockexpression;
	}

	/**
	 * Given some type that is used in a generic superclass or interface of this
	 * type element, this method resolves the contained type variables according
	 * to the resolvedSuperTypeArgs.
	 */
	@Override
	protected TypeMirror resolveTypeVariable(final TypeVariable tv) {
		TypeMirror _xblockexpression = null;
		{
			final TypeMirror resolvedTypeVar = this.resolvedTypeArgsMap.get(tv.asElement());
			if (((resolvedTypeVar == null) && Objects.equal(this.nestingKind, NestingKind.TOP_LEVEL))) {
			}
			_xblockexpression = resolvedTypeVar;
		}
		return _xblockexpression;
	}

	@Override
	public void addEnclosedElement(final Element enclosed) {
		super.addEnclosedElement(enclosed);
		((GenElement) enclosed).resolveContainedTypeVariables(this);
	}

	private static final Function2<Element, Element, Integer> memberComparator = ((Function2<Element, Element, Integer>) (Element e1,
			Element e2) -> {
		return Integer
				.valueOf(Integer.valueOf(GenTypeElement.memberOrderOf(e1)).compareTo(Integer.valueOf(GenTypeElement.memberOrderOf(e2))));
	});

	private static final List<ElementKind> memberOrder = Collections
			.unmodifiableList(asList(ElementKind.ENUM_CONSTANT, ElementKind.FIELD, ElementKind.STATIC_INIT, ElementKind.INSTANCE_INIT,
					ElementKind.CONSTRUCTOR, ElementKind.METHOD, ElementKind.ENUM, ElementKind.INTERFACE, ElementKind.CLASS));

	public static int memberOrderOf(final Element e) {
		int _xblockexpression = 0;
		{
			final int index = GenTypeElement.memberOrder.indexOf(e.getKind());
			int _xifexpression = 0;
			if ((index >= 0)) {
				_xifexpression = index;
			} else {
				_xifexpression = GenTypeElement.memberOrder.size();
			}
			_xblockexpression = _xifexpression;
		}
		return _xblockexpression;
	}

	@Override
	public Comparator<Element> enclosedElementComparator() {
		return new Comparator<Element>() {
			@Override
			public int compare(Element o1, Element o2) {
				return GenTypeElement.memberComparator.apply(o1, o2);
			}
		};
	}

	public List<ExecutableElement> allMethods() {
		List<ExecutableElement> _xblockexpression = null;
		{
			@Extension
			final TypesExtensions TypesExtensions = ExtensionRegistry.<de.japkit.services.TypesExtensions> get(
					de.japkit.services.TypesExtensions.class);
			@Extension
			final ElementsExtensions ElementsExtensions = ExtensionRegistry.<de.japkit.services.ElementsExtensions> get(
					de.japkit.services.ElementsExtensions.class);
			final List<ExecutableElement> methods = new ArrayList<>();
			final GenTypeElement te = this;
			if ((this.superclass != null)) {
				final Function1<ExecutableElement, Boolean> _function = (ExecutableElement m) -> {
					return Boolean.valueOf(((!IterableExtensions.<ExecutableElement> exists(ElementsExtensions.declaredMethods(this),
							((Function1<ExecutableElement, Boolean>) (ExecutableElement it) -> {
								return Boolean.valueOf(ElementsExtensions.overrides(it, m));
							}))) && ((ElementsExtensions.isPublic(m) || ElementsExtensions.isProtected(m))
									|| (ElementsExtensions.isDefaultAccess(m) && ElementsExtensions.samePackage(m, te)))));
				};
				final Function1<ExecutableElement, GenMethod> _function_1 = (ExecutableElement m) -> {
					GenMethod _xblockexpression_1 = null;
					{
						final GenMethod m1 = ExtensionRegistry.<GenExtensions> get(GenExtensions.class).asMemberOf(m, te);
						_xblockexpression_1 = m1;
					}
					return _xblockexpression_1;
				};
				Iterables.<ExecutableElement> addAll(methods,
						IterableExtensions.<ExecutableElement, GenMethod> map(
								IterableExtensions.<ExecutableElement> filter(
										ElementsExtensions.allMethods(TypesExtensions.asElement(this.superclass)), _function),
								_function_1));
			}
			methods.addAll(ElementsExtensions.declaredMethods(this));
			_xblockexpression = methods;
		}
		return _xblockexpression;
	}

	@Override
	public TypeMirror asType() {
		// create the type. potentially prototypical
		return new GenDeclaredType(this, getTypeParameters().stream().map(p -> p.asType()).collect(toList()));
	}

	public GenTypeElement(final String name) {
		super(name);
	}

	public GenTypeElement(final Name name) {
		super(name);
	}

	public GenTypeElement() {
	}

	@Override
	public List<? extends TypeMirror> getInterfaces() {
		return java.util.Collections.unmodifiableList(interfaces);
	}

	public void removeInterface(final TypeMirror aInterface_) {
		this.interfaces.remove(aInterface_);
	}

	public void setInterfaces(final List<? extends TypeMirror> interfaces) {
		this.interfaces.clear();
		for (TypeMirror aInterface_ : interfaces) {
			addInterface(aInterface_);
		}
	}

	@Override
	public NestingKind getNestingKind() {
		return nestingKind;
	}

	public void setNestingKind(final NestingKind nestingKind) {
		this.nestingKind = nestingKind;
	}

	public void setQualifiedName(final Name qualifiedName) {
		this.qualifiedName = qualifiedName;
	}

	@Override
	public TypeMirror getSuperclass() {
		return superclass;
	}

	public void setSuperclass(final TypeMirror superclass) {
		this.superclass = superclass;
	}

	@Pure
	public Set<GenTypeElement> getAuxTopLevelClasses() {
		return this.auxTopLevelClasses;
	}

	public void setAuxTopLevelClasses(final Set<GenTypeElement> auxTopLevelClasses) {
		this.auxTopLevelClasses = auxTopLevelClasses;
	}

	@Pure
	public boolean isAuxClass() {
		return this.auxClass;
	}

	public void setAuxClass(final boolean auxClass) {
		this.auxClass = auxClass;
	}
}
