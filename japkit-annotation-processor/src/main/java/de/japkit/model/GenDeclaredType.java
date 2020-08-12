package de.japkit.model;

import java.util.List;

import javax.lang.model.element.Element;
import javax.lang.model.element.TypeElement;
import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeKind;
import javax.lang.model.type.TypeMirror;
import javax.lang.model.type.TypeVisitor;

import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;

public class GenDeclaredType extends GenTypeMirror implements DeclaredType {
	private TypeElement element;

	private TypeMirror enclosingType;

	private List<TypeMirror> typeArguments = CollectionLiterals.newArrayList();

	@Override
	public Element asElement() {
		return this.element;
	}

	@Override
	public String toString() {
		StringConcatenation _builder = new StringConcatenation();
		String _qualifiedName = this.qualifiedName();
		_builder.append(_qualifiedName);
		{
			boolean _hasElements = false;
			for (final TypeMirror a : this.typeArguments) {
				if (!_hasElements) {
					_hasElements = true;
					_builder.append("<");
				} else {
					_builder.appendImmediate(",", "");
				}
				_builder.append(a);
			}
			if (_hasElements) {
				_builder.append(">");
			}
		}
		return _builder.toString();
	}

	public String qualifiedName() {
		return this.element.getQualifiedName().toString();
	}

	public String simpleName() {
		return this.element.getSimpleName().toString();
	}

	public GenDeclaredType(final TypeElement element) {
		this.element = element;
	}

	public GenDeclaredType(final TypeElement element, final Procedure1<? super GenDeclaredType> initializer) {
		this.element = element;
		initializer.apply(this);
	}

	public GenDeclaredType erasure() {
		return new GenDeclaredType(this.element);
	}

	@Override
	public <R extends Object, P extends Object> R accept(final TypeVisitor<R, P> v, final P p) {
		return v.visitDeclared(this, p);
	}

	@Override
	public TypeMirror getEnclosingType() {
		return enclosingType;
	}

	public void setEnclosingType(final TypeMirror enclosingType) {
		this.enclosingType = enclosingType;
	}

	@Override
	public List<? extends TypeMirror> getTypeArguments() {
		return java.util.Collections.unmodifiableList(typeArguments);
	}

	public void addTypeArgument(final TypeMirror aTypeArgument_) {
		this.typeArguments.add(aTypeArgument_);
	}

	public void removeTypeArgument(final TypeMirror aTypeArgument_) {
		this.typeArguments.remove(aTypeArgument_);
	}

	public void setTypeArguments(final List<? extends TypeMirror> typeArguments) {
		this.typeArguments.clear();
		for (TypeMirror aTypeArgument_ : typeArguments) {
			addTypeArgument(aTypeArgument_);
		}
	}

	@Override
	public TypeKind getKind() {
		return TypeKind.DECLARED;
	}
}
