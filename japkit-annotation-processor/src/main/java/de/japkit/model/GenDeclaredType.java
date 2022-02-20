package de.japkit.model;

import static java.util.Collections.unmodifiableList;
import static java.util.stream.Collectors.joining;

import java.util.ArrayList;
import java.util.List;

import javax.lang.model.element.Element;
import javax.lang.model.element.TypeElement;
import javax.lang.model.type.DeclaredType;
import javax.lang.model.type.TypeKind;
import javax.lang.model.type.TypeMirror;
import javax.lang.model.type.TypeVisitor;
import javax.lang.model.util.Types;

/**
 * A generated declared type.
 * 
 * @author stefan
 */
public class GenDeclaredType extends GenTypeMirror implements DeclaredType {
	/**
	 * The type element corresponding to this type.
	 */
	private TypeElement element;

	/**
	 * The type of the innermost enclosing instance. Only types corresponding to
	 * inner classes have an enclosing instance.
	 */
	private TypeMirror enclosingType;

	/**
	 * The actual type arguments of this type.
	 */
	private List<TypeMirror> typeArguments = new ArrayList<>();

	/**
	 * @param element see {@link #element}.
	 */
	public GenDeclaredType(final TypeElement element) {
		this.element = element;
	}

	/**
	 * @param element see {@link #element}
	 * @param typeArguments see {@link #typeArguments}
	 */
	public GenDeclaredType(final TypeElement element, final List<? extends TypeMirror> typeArguments) {
		// TODO: Proper handling of enclosing type?
		this.element = element;
		this.typeArguments = new ArrayList<>(typeArguments);
	}

	@Override
	public <R extends Object, P extends Object> R accept(final TypeVisitor<R, P> v, final P p) {
		return v.visitDeclared(this, p);
	}

	@Override
	public Element asElement() {
		return this.element;
	}

	/**
	 * @return the erasure of this type. See also
	 *         {@link Types#erasure(TypeMirror)}.
	 */
	public GenDeclaredType erasure() {
		// TODO: Proper handling of enclosing type?
		return new GenDeclaredType(this.element);
	}

	@Override
	public TypeMirror getEnclosingType() {
		return enclosingType;
	}

	@Override
	public TypeKind getKind() {
		return TypeKind.DECLARED;
	}

	@Override
	public List<? extends TypeMirror> getTypeArguments() {
		return unmodifiableList(typeArguments);
	}

	/**
	 * @return the qualified name of the corresponding type element.
	 */
	public String qualifiedName() {
		return this.element.getQualifiedName().toString();
	}

	/**
	 * @return the simple name of the corresponding type element.
	 */
	public String simpleName() {
		return this.element.getSimpleName().toString();
	}

	@Override
	public String toString() {
		String argsString = typeArguments.isEmpty() ? "" : "<" + typeArguments.stream().map(a -> a.toString()).collect(joining(",")) + ">";
		return qualifiedName() + argsString;
	}
}
