package de.japkit.model;

import java.util.List;
import java.util.function.Consumer;

import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.Modifier;
import javax.lang.model.element.Name;
import javax.lang.model.element.TypeParameterElement;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeKind;
import javax.lang.model.type.TypeMirror;
import javax.lang.model.type.TypeVariable;

import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Functions.Function0;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;

import com.google.common.base.Objects;

import de.japkit.services.ExtensionRegistry;
import de.japkit.services.TypesExtensions;

public abstract class GenExecutableElement extends GenParameterizable implements ExecutableElement {
	private CodeBody body;

	private AnnotationValue defaultValue;

	private List<VariableElement> parameters = CollectionLiterals.newArrayList();

	private TypeMirror returnType = new Function0<TypeMirror>() {
		@Override
		public TypeMirror apply() {
			return ExtensionRegistry.get(TypesExtensions.class).getNoType(TypeKind.VOID);
		}
	}.apply();

	private List<TypeMirror> thrownTypes = CollectionLiterals.newArrayList();

	private boolean varArgs;

	private TypeMirror receiverType;

	private boolean default_;

	public CodeBody getBody() {
		return this.body;
	}

	public void setBody(final CodeBody body) {
		this.body = body;
		if ((body != null)) {
			this.removeModifier(Modifier.ABSTRACT);
		}
	}

	@Override
	public void addModifier(final Modifier m) {
		if (((this.body != null) && Objects.equal(m, Modifier.ABSTRACT))) {
			return;
		}
		super.addModifier(m);
	}

	public void addParameter(final VariableElement ve) {
		final GenParameter p = ((GenParameter) ve);
		this.parameters.add(p);
		p.setEnclosingElement(this);
	}

	@Override
	public TypeMirror resolveTypeVariable(final TypeVariable tv) {
		TypeVariable _xifexpression = null;
		final Function1<TypeParameterElement, Boolean> _function = (TypeParameterElement it) -> {
			return Boolean.valueOf(it.getSimpleName().contentEquals(tv.asElement().getSimpleName()));
		};
		boolean _exists = IterableExtensions.exists(this.getTypeParameters(), _function);
		if (_exists) {
			_xifexpression = tv;
		} else {
			_xifexpression = null;
		}
		return _xifexpression;
	}

	@Override
	public void resolveContainedTypeVariables(final GenParameterizable parameterizable) {
		this.returnType = parameterizable.resolveTypeVariables(this.returnType);
		final Consumer<VariableElement> _function = (VariableElement p) -> {
			((GenVariableElement) p).resolveContainedTypeVariables(parameterizable);
		};
		this.parameters.forEach(_function);
	}

	public GenExecutableElement(final String simpleName) {
		super(simpleName);
	}

	public GenExecutableElement(final Name simpleName) {
		super(simpleName);
	}

	public void setReturnType(final TypeMirror returnType) {
		TypeMirror _xifexpression = null;
		if ((((returnType == null) || Objects.equal(returnType.getKind(), TypeKind.NONE))
				|| Objects.equal(returnType.getKind(), TypeKind.NULL))) {
			_xifexpression = ExtensionRegistry.<TypesExtensions> get(TypesExtensions.class).getNoType(TypeKind.VOID);
		} else {
			_xifexpression = returnType;
		}
		this.returnType = _xifexpression;
	}

	@Override
	public String toString() {
		StringConcatenation _builder = new StringConcatenation();
		_builder.append(this.returnType);
		_builder.append(" ");
		Name _simpleName = this.getSimpleName();
		_builder.append(_simpleName);
		_builder.append("(");
		{
			boolean _hasElements = false;
			for (final VariableElement p : this.parameters) {
				if (!_hasElements) {
					_hasElements = true;
				} else {
					_builder.appendImmediate(", ", "");
				}
				_builder.append("p");
			}
		}
		_builder.append(")");
		return _builder.toString();
	}

	@Override
	public AnnotationValue getDefaultValue() {
		return defaultValue;
	}

	public void setDefaultValue(final AnnotationValue defaultValue) {
		this.defaultValue = defaultValue;
	}

	@Override
	public List<? extends VariableElement> getParameters() {
		return java.util.Collections.unmodifiableList(parameters);
	}

	public void removeParameter(final VariableElement aParameter_) {
		this.parameters.remove(aParameter_);
	}

	public void setParameters(final List<? extends VariableElement> parameters) {
		this.parameters.clear();
		for (VariableElement aParameter_ : parameters) {
			addParameter(aParameter_);
		}
	}

	@Override
	public TypeMirror getReceiverType() {
		return receiverType;
	}

	public void setReceiverType(final TypeMirror receiverType) {
		this.receiverType = receiverType;
	}

	@Override
	public TypeMirror getReturnType() {
		return returnType;
	}

	@Override
	public List<? extends TypeMirror> getThrownTypes() {
		return java.util.Collections.unmodifiableList(thrownTypes);
	}

	public void addThrownType(final TypeMirror aThrownType_) {
		this.thrownTypes.add(aThrownType_);
	}

	public void removeThrownType(final TypeMirror aThrownType_) {
		this.thrownTypes.remove(aThrownType_);
	}

	public void setThrownTypes(final List<? extends TypeMirror> thrownTypes) {
		this.thrownTypes.clear();
		for (TypeMirror aThrownType_ : thrownTypes) {
			addThrownType(aThrownType_);
		}
	}

	@Override
	public boolean isDefault() {
		return default_;
	}

	public void setDefault(final boolean default_) {
		this.default_ = default_;
	}

	@Override
	public boolean isVarArgs() {
		return varArgs;
	}

	public void setVarArgs(final boolean varArgs) {
		this.varArgs = varArgs;
	}

	public GenExecutableElement() {
		super();
	}
}
