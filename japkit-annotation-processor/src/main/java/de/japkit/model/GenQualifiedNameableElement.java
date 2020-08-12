package de.japkit.model;

import javax.lang.model.element.Name;
import javax.lang.model.element.QualifiedNameable;

import org.eclipse.xtend2.lib.StringConcatenation;

public abstract class GenQualifiedNameableElement extends GenElement implements QualifiedNameable {

	@Override
	public Name getQualifiedName() {
		StringConcatenation _builder = new StringConcatenation();
		_builder.append("(enclosingElement as QualifiedNameable)?.qualifiedName».");
		Name _simpleName = this.getSimpleName();
		_builder.append(_simpleName);
		return new GenName(_builder.toString());
	}

	public GenQualifiedNameableElement() {
		super();
	}

	public GenQualifiedNameableElement(final Name simpleName) {
		super(simpleName);
	}

	public GenQualifiedNameableElement(final String simpleName) {
		super(simpleName);
	}
}
