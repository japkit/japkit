package de.japkit.model;

import javax.lang.model.type.ErrorType;
import javax.lang.model.type.TypeVisitor;

import org.eclipse.xtext.xbase.lib.IterableExtensions;

/**
 * A type that has been created during code generation but that could not be
 * resolved so far, sine the type element is not available or has not been
 * generated yet.
 */
public class GenUnresolvedType extends GenDeclaredType implements ErrorType {
	private String qualifiedName_;

	private String simpleName_;

	private boolean innerClass;

	public GenUnresolvedType(final String qualifiedName, final boolean innerClass) {
		super(null);
		this.qualifiedName_ = qualifiedName;
		int _lastIndexOf = qualifiedName.lastIndexOf(".");
		int _plus = (_lastIndexOf + 1);
		this.simpleName_ = qualifiedName.substring(_plus);
		this.innerClass = innerClass;
	}

	@Override
	public String qualifiedName() {
		return this.qualifiedName_;
	}

	@Override
	public String simpleName() {
		return this.simpleName_;
	}

	public String getEnclosingQualifiedName() {
		return this.qualifiedName().substring(0, this.qualifiedName().lastIndexOf("."));
	}

	@Override
	public GenDeclaredType erasure() {
		GenUnresolvedType _xifexpression = null;
		boolean _isNullOrEmpty = IterableExtensions.isNullOrEmpty(this.getTypeArguments());
		if (_isNullOrEmpty) {
			_xifexpression = this;
		} else {
			_xifexpression = new GenUnresolvedType(this.qualifiedName_, this.innerClass);
		}
		return _xifexpression;
	}

	public boolean isInnerClass() {
		return this.innerClass;
	}

	@Override
	public <R extends Object, P extends Object> R accept(final TypeVisitor<R, P> v, final P p) {
		return v.visitError(this, p);
	}
}
