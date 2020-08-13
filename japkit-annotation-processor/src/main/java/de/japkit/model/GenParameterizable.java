package de.japkit.model;

import java.util.ArrayList;
import java.util.List;

import javax.lang.model.element.Element;
import javax.lang.model.element.Name;
import javax.lang.model.element.Parameterizable;
import javax.lang.model.element.TypeElement;
import javax.lang.model.element.TypeParameterElement;
import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.ErrorType;
import javax.lang.model.type.TypeMirror;
import javax.lang.model.type.TypeVariable;
import javax.lang.model.util.SimpleTypeVisitor8;

import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.ListExtensions;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;

import de.japkit.services.ExtensionRegistry;
import de.japkit.services.TypesExtensions;

public abstract class GenParameterizable extends GenElement implements Parameterizable {
	private List<TypeParameterElement> typeParameters = new ArrayList<>();

	public DeclaredType getDeclaredType(final DeclaredType prototype, final Iterable<TypeMirror> resolvedTypeArgs) {
		DeclaredType _xifexpression = null;
		if ((prototype instanceof GenDeclaredType)) {
			Element _asElement = ((GenDeclaredType) prototype).asElement();
			final Procedure1<GenDeclaredType> _function = (GenDeclaredType it) -> {
				it.setTypeArguments(IterableExtensions.<TypeMirror> toList(resolvedTypeArgs));
			};
			_xifexpression = new GenDeclaredType(((TypeElement) _asElement), _function);
		} else {
			Element _asElement_1 = prototype.asElement();
			_xifexpression = ExtensionRegistry.<TypesExtensions> get(TypesExtensions.class).getDeclaredType(((TypeElement) _asElement_1),
					((TypeMirror[]) Conversions.unwrapArray(resolvedTypeArgs, TypeMirror.class)));
		}
		return _xifexpression;
	}

	public TypeMirror resolveTypeVariables(final TypeMirror type) {
		TypeMirror _accept = null;
		if (type != null) {
			_accept = type.<TypeMirror, Void> accept(new SimpleTypeVisitor8<TypeMirror, Void>() {
				@Override
				public TypeMirror defaultAction(final TypeMirror type, final Void p) {
					return type;
				}

				@Override
				public TypeMirror visitDeclared(final DeclaredType type, final Void p) {
					DeclaredType _xifexpression = null;
					boolean _isNullOrEmpty = IterableExtensions.isNullOrEmpty(type.getTypeArguments());
					if (_isNullOrEmpty) {
						_xifexpression = type;
					} else {
						final Function1<TypeMirror, TypeMirror> _function = (TypeMirror it) -> {
							return GenParameterizable.this.resolveTypeVariables(it);
						};
						_xifexpression = GenParameterizable.this.getDeclaredType(type,
								ListExtensions.map(type.getTypeArguments(), _function));
					}
					return _xifexpression;
				}

				@Override
				public TypeMirror visitError(final ErrorType type, final Void p) {
					return this.visitDeclared(type, p);
				}

				@Override
				public TypeMirror visitTypeVariable(final TypeVariable tv, final Void p) {
					TypeMirror _xblockexpression = null;
					{
						TypeMirror resolvedTypeVar = GenParameterizable.this.resolveTypeVariable(tv);
						if ((resolvedTypeVar == null)) {
							GenParameterizable _enclosingParameterizable = GenParameterizable.this.enclosingParameterizable();
							boolean _tripleNotEquals = (_enclosingParameterizable != null);
							if (_tripleNotEquals) {
								resolvedTypeVar = GenParameterizable.this.enclosingParameterizable().resolveTypeVariables(tv);
							} else {
								resolvedTypeVar = tv;
							}
						}
						_xblockexpression = resolvedTypeVar;
					}
					return _xblockexpression;
				}
			}, null);
		}
		return _accept;
	}

	/**
	 * resolve the type variable "locally" , for example by using type arguments
	 * of the method / class
	 */
	protected abstract TypeMirror resolveTypeVariable(final TypeVariable tv);

	/**
	 * Gets or creates a type parameter with the same name and bounds as the
	 * given type parameter (typically from a superclass)
	 */
	public TypeParameterElement getOrCreateTypeParameter(final TypeParameterElement otherTypeParam) {
		TypeParameterElement _elvis = null;
		final Function1<TypeParameterElement, Boolean> _function = (TypeParameterElement it) -> {
			return Boolean.valueOf(it.getSimpleName().contentEquals(otherTypeParam.getSimpleName()));
		};
		TypeParameterElement _head = IterableExtensions
				.<TypeParameterElement> head(IterableExtensions.<TypeParameterElement> filter(this.typeParameters, _function));
		if (_head != null) {
			_elvis = _head;
		} else {
			_elvis = new GenTypeParameter(otherTypeParam, this);
		}
		return _elvis;
	}

	public GenParameterizable(final String simpleName) {
		super(simpleName);
	}

	public GenParameterizable(final Name simpleName) {
		super(simpleName);
	}

	@Override
	public List<? extends TypeParameterElement> getTypeParameters() {
		return java.util.Collections.unmodifiableList(typeParameters);
	}

	public void addTypeParameter(final TypeParameterElement aTypeParameter_) {
		this.typeParameters.add(aTypeParameter_);
	}

	public void removeTypeParameter(final TypeParameterElement aTypeParameter_) {
		this.typeParameters.remove(aTypeParameter_);
	}

	public void setTypeParameters(final List<? extends TypeParameterElement> typeParameters) {
		this.typeParameters.clear();
		for (TypeParameterElement aTypeParameter_ : typeParameters) {
			addTypeParameter(aTypeParameter_);
		}
	}

	public GenParameterizable() {
		super();
	}
}
