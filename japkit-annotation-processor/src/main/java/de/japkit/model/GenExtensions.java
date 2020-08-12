package de.japkit.model;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Consumer;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.Modifier;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeElement;
import javax.lang.model.element.TypeParameterElement;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeMirror;

import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Extension;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.ListExtensions;
import org.eclipse.xtext.xbase.lib.ObjectExtensions;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;

import com.google.common.base.Objects;

import de.japkit.annotations.Order;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.rules.TypeResolver;
import de.japkit.services.ElementsExtensions;
import de.japkit.services.ExtensionRegistry;
import de.japkit.services.TypeElementNotFoundException;

public class GenExtensions {
	@Extension
	private final transient ElementsExtensions _elementsExtensions = ExtensionRegistry.get(ElementsExtensions.class);

	@Extension
	private final transient TypeResolver _typeResolver = ExtensionRegistry.<TypeResolver> get(TypeResolver.class);

	public GenMethod createOverride(final ExecutableElement m, final CodeBody b) {
		GenMethod _copyFrom = this.copyFrom(m);
		final Procedure1<GenMethod> _function = (GenMethod it) -> {
			ElementKind _kind = m.getEnclosingElement().getKind();
			boolean _equals = Objects.equal(_kind, ElementKind.INTERFACE);
			if (_equals) {
				it.addModifier(Modifier.PUBLIC);
			}
			it.setBody(b);
		};
		return ObjectExtensions.<GenMethod> operator_doubleArrow(_copyFrom, _function);
	}

	public GenMethod copyFrom(final ExecutableElement m) {
		return this.copyFrom(m, false);
	}

	public GenMethod copyFrom(final ExecutableElement m, final boolean copyAnnotations) {
		final Function1<TypeMirror, TypeMirror> _function = (TypeMirror t) -> {
			return t;
		};
		GenElement _copyFrom = this.copyFrom(m, copyAnnotations, _function);
		return ((GenMethod) _copyFrom);
	}

	protected GenElement _copyFrom(final ExecutableElement m, final boolean copyAnnotations,
			final Function1<? super TypeMirror, ? extends TypeMirror> typeTransformer) {
		GenExecutableElement _xblockexpression = null;
		{
			GenExecutableElement _xifexpression = null;
			ElementKind _kind = m.getKind();
			boolean _equals = Objects.equal(_kind, ElementKind.METHOD);
			if (_equals) {
				Name _simpleName = m.getSimpleName();
				_xifexpression = new GenMethod(_simpleName);
			} else {
				GenConstructor _xifexpression_1 = null;
				ElementKind _kind_1 = m.getKind();
				boolean _equals_1 = Objects.equal(_kind_1, ElementKind.CONSTRUCTOR);
				if (_equals_1) {
					_xifexpression_1 = new GenConstructor();
				} else {
					StringConcatenation _builder = new StringConcatenation();
					_builder.append("Copying ");
					_builder.append(m);
					_builder.append(" not supported.");
					throw new IllegalArgumentException(_builder.toString());
				}
				_xifexpression = _xifexpression_1;
			}
			final GenExecutableElement result = _xifexpression;
			final Procedure1<GenExecutableElement> _function = (GenExecutableElement it) -> {
				if (copyAnnotations) {
					it.setAnnotationMirrors(this.copyAnnotations(m));
				}
				ElementKind _kind_2 = m.getKind();
				boolean _equals_2 = Objects.equal(_kind_2, ElementKind.METHOD);
				if (_equals_2) {
					TypeMirror _apply = typeTransformer.apply(m.getReturnType());
					TypeMirror _resolveType = null;
					if (_apply != null) {
						_resolveType = this._typeResolver.resolveType(_apply);
					}
					it.setReturnType(_resolveType);
				}
				final Function1<TypeMirror, TypeMirror> _function_1 = (TypeMirror it_1) -> {
					return typeTransformer.apply(it_1);
				};
				it.setThrownTypes(ListExtensions.map(m.getThrownTypes(), _function_1));
				final Function1<TypeParameterElement, TypeParameterElement> _function_2 = (TypeParameterElement tp) -> {
					return it.getOrCreateTypeParameter(tp);
				};
				it.setTypeParameters(ListExtensions.map(m.getTypeParameters(), _function_2));
				it.setVarArgs(m.isVarArgs());
				it.setParameters(this.copyParametersFrom(m, copyAnnotations, typeTransformer));
				it.setModifiers(m.getModifiers());
			};
			_xblockexpression = ObjectExtensions.<GenExecutableElement> operator_doubleArrow(result, _function);
		}
		return _xblockexpression;
	}

	public List<GenParameter> copyParametersFrom(final ExecutableElement m, final boolean copyAnnotations) {
		final Function1<TypeMirror, TypeMirror> _function = (TypeMirror t) -> {
			return t;
		};
		return this.copyParametersFrom(m, copyAnnotations, _function);
	}

	public List<GenParameter> copyParametersFrom(final ExecutableElement method, final boolean copyAnnotations,
			final Function1<? super TypeMirror, ? extends TypeMirror> typeTransformer) {
		final Function1<VariableElement, GenParameter> _function = (VariableElement p) -> {
			return this.copyParamFrom(p, copyAnnotations, typeTransformer);
		};
		return ListExtensions.map(this._elementsExtensions.parametersWithSrcNames(method), _function);
	}

	public GenParameter copyParamFrom(final VariableElement p, final boolean copyAnnotations,
			final Function1<? super TypeMirror, ? extends TypeMirror> typeTransformer) {
		Name _simpleName = p.getSimpleName();
		TypeMirror _apply = typeTransformer.apply(p.asType());
		GenParameter _genParameter = new GenParameter(_simpleName, _apply);
		final Procedure1<GenParameter> _function = (GenParameter it) -> {
			if (copyAnnotations) {
				it.setAnnotationMirrors(this.copyAnnotations(p));
			}
		};
		return ObjectExtensions.<GenParameter> operator_doubleArrow(_genParameter, _function);
	}

	protected GenElement _copyFrom(final VariableElement ve, final boolean copyAnnotations,
			final Function1<? super TypeMirror, ? extends TypeMirror> typeTransformer) {
		Name _simpleName = ve.getSimpleName();
		TypeMirror _asType = ve.asType();
		TypeMirror _resolveType = null;
		if (_asType != null) {
			_resolveType = this._typeResolver.resolveType(_asType);
		}
		TypeMirror _apply = typeTransformer.apply(_resolveType);
		GenField _genField = new GenField(_simpleName, _apply);
		final Procedure1<GenField> _function = (GenField it) -> {
			it.setModifiers(ve.getModifiers());
			if (copyAnnotations) {
				it.setAnnotationMirrors(this.copyAnnotations(ve));
			}
		};
		return ObjectExtensions.<GenField> operator_doubleArrow(_genField, _function);
	}

	public GenMethod asMemberOf(final ExecutableElement m, final TypeElement type) {
		GenMethod _copyFrom = this.copyFrom(m);
		final Procedure1<GenMethod> _function = (GenMethod it) -> {
			it.setEnclosingElement(m.getEnclosingElement());
			it.resolveContainedTypeVariables(((GenTypeElement) type));
		};
		return ObjectExtensions.<GenMethod> operator_doubleArrow(_copyFrom, _function);
	}

	public GenMethod asInterfaceMethod(final ExecutableElement m) {
		GenMethod _copyFrom = this.copyFrom(m);
		final Procedure1<GenMethod> _function = (GenMethod it) -> {
			it.setModifiers(CollectionLiterals.<Modifier> emptySet());
			it.setBody(null);
		};
		return ObjectExtensions.<GenMethod> operator_doubleArrow(_copyFrom, _function);
	}

	public GenMethod asAbstractMethod(final ExecutableElement m) {
		GenMethod _copyFrom = this.copyFrom(m);
		final Procedure1<GenMethod> _function = (GenMethod it) -> {
			it.addModifier(Modifier.ABSTRACT);
			it.setBody(null);
		};
		return ObjectExtensions.<GenMethod> operator_doubleArrow(_copyFrom, _function);
	}

	private final Set<String> japkitAnnotationPackages = Collections.<String> unmodifiableSet(CollectionLiterals.<String> newHashSet(
			Clazz.class.getPackage().getName(), Order.class.getPackage().getName(), ClassSelector.class.getPackage().getName()));

	public boolean isJapkitAnnotation(final AnnotationMirror am) {
		return this.japkitAnnotationPackages.contains(
				this._elementsExtensions.getPackage(this._elementsExtensions.annotationAsTypeElement(am)).getQualifiedName().toString());
	}

	public final Function1<AnnotationMirror, Boolean> isNoJapkitAnnotationFilter = ((Function1<AnnotationMirror, Boolean>) (
			AnnotationMirror am) -> {
		boolean _isJapkitAnnotation = this.isJapkitAnnotation(am);
		return Boolean.valueOf((!_isJapkitAnnotation));
	});

	public ArrayList<GenAnnotationMirror> copyAnnotations(final Element src) {
		final Function1<Object, Object> _function = (Object it) -> {
			return it;
		};
		return this.copyAnnotations(src, this.isNoJapkitAnnotationFilter, _function);
	}

	public ArrayList<GenAnnotationMirror> copyAnnotations(final Element src,
			final Function1<? super AnnotationMirror, ? extends Boolean> filter, final Function1<? super Object, ?> valueTransformer) {
		final Function1<AnnotationMirror, GenAnnotationMirror> _function = (AnnotationMirror it) -> {
			return GenExtensions.copy(it, valueTransformer);
		};
		List<GenAnnotationMirror> _list = IterableExtensions.<GenAnnotationMirror> toList(IterableExtensions.map(
				IterableExtensions.filter(src.getAnnotationMirrors(), ((Function1<? super AnnotationMirror, Boolean>) filter)), _function));
		return new ArrayList<GenAnnotationMirror>(_list);
	}

	public static GenAnnotationMirror copy(final AnnotationMirror am) {
		final Function1<Object, Object> _function = (Object it) -> {
			return it;
		};
		return GenExtensions.copy(am, _function);
	}

	public static GenAnnotationMirror copy(final AnnotationMirror am, final Function1<? super Object, ?> valueTransformer) {
		DeclaredType _annotationType = am.getAnnotationType();
		GenAnnotationMirror _genAnnotationMirror = new GenAnnotationMirror(_annotationType);
		final Procedure1<GenAnnotationMirror> _function = (GenAnnotationMirror it) -> {
			final Consumer<Map.Entry<? extends ExecutableElement, ? extends AnnotationValue>> _function_1 = (
					Map.Entry<? extends ExecutableElement, ? extends AnnotationValue> avEntry) -> {
				it.setValue(avEntry.getKey().getSimpleName().toString(), GenExtensions.copy(avEntry.getValue(), valueTransformer));
			};
			am.getElementValues().entrySet().forEach(_function_1);
		};
		return ObjectExtensions.<GenAnnotationMirror> operator_doubleArrow(_genAnnotationMirror, _function);
	}

	public static GenAnnotationValue copy(final AnnotationValue av, final Function1<? super Object, ?> valueTransformer) {
		GenAnnotationValue _xblockexpression = null;
		{
			@Extension
			final ElementsExtensions ElementsExtensions = ExtensionRegistry.<de.japkit.services.ElementsExtensions> get(
					de.japkit.services.ElementsExtensions.class);
			Object _copyAvValue = GenExtensions.copyAvValue(ElementsExtensions.getValueWithErrorHandling(av), valueTransformer);
			_xblockexpression = new GenAnnotationValue(_copyAvValue);
		}
		return _xblockexpression;
	}

	protected static Object _copyAvValue(final List<? extends AnnotationValue> values,
			final Function1<? super Object, ?> valueTransformer) {
		final Function1<AnnotationValue, GenAnnotationValue> _function = (AnnotationValue it) -> {
			return GenExtensions.copy(it, valueTransformer);
		};
		List<GenAnnotationValue> _map = ListExtensions.map(values, _function);
		return new ArrayList<GenAnnotationValue>(_map);
	}

	protected static Object _copyAvValue(final AnnotationMirror v, final Function1<? super Object, ?> valueTransformer) {
		return GenExtensions.copy(v, valueTransformer);
	}

	protected static Object _copyAvValue(final Object v, final Function1<? super Object, ?> valueTransformer) {
		boolean _equals = Objects.equal(v, "<error>");
		if (_equals) {
			throw new TypeElementNotFoundException();
		}
		return valueTransformer.apply(v);
	}

	public GenElement copyFrom(final Element m, final boolean copyAnnotations,
			final Function1<? super TypeMirror, ? extends TypeMirror> typeTransformer) {
		if (m instanceof ExecutableElement && typeTransformer != null) {
			return _copyFrom((ExecutableElement) m, copyAnnotations, typeTransformer);
		} else if (m instanceof VariableElement && typeTransformer != null) {
			return _copyFrom((VariableElement) m, copyAnnotations, typeTransformer);
		} else {
			throw new IllegalArgumentException(
					"Unhandled parameter types: " + Arrays.<Object> asList(m, copyAnnotations, typeTransformer).toString());
		}
	}

	public static Object copyAvValue(final Object values, final Function1<? super Object, ?> valueTransformer) {
		if (values instanceof List && valueTransformer != null) {
			return _copyAvValue((List<? extends AnnotationValue>) values, valueTransformer);
		} else if (values instanceof AnnotationMirror && valueTransformer != null) {
			return _copyAvValue((AnnotationMirror) values, valueTransformer);
		} else if (values != null && valueTransformer != null) {
			return _copyAvValue(values, valueTransformer);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object> asList(values, valueTransformer).toString());
		}
	}
}
