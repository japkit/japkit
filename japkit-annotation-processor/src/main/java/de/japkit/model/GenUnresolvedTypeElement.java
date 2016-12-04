package de.japkit.model;

import java.lang.annotation.Annotation;
import java.util.List;
import java.util.Set;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;
import javax.lang.model.element.ElementVisitor;
import javax.lang.model.element.Modifier;
import javax.lang.model.element.Name;
import javax.lang.model.element.NestingKind;
import javax.lang.model.element.TypeElement;
import javax.lang.model.element.TypeParameterElement;
import javax.lang.model.type.TypeMirror;

import de.japkit.services.TypeElementNotFoundException;

public class GenUnresolvedTypeElement implements TypeElement {
	private GenUnresolvedType type;

	public GenUnresolvedTypeElement(GenUnresolvedType type) {
		this.type = type;
	}

	@Override
	public TypeMirror asType() {
		return type;
	}

	@Override
	public ElementKind getKind() {
		throw typeElementNotFoundException();
	}

	private TypeElementNotFoundException typeElementNotFoundException() {
		return new TypeElementNotFoundException(type.qualifiedName());
	}

	@Override
	public Set<Modifier> getModifiers() {
		throw typeElementNotFoundException();
	}

	@Override
	public List<? extends AnnotationMirror> getAnnotationMirrors() {
		throw typeElementNotFoundException();
	}

	@Override
	public <A extends Annotation> A getAnnotation(Class<A> annotationType) {
		throw typeElementNotFoundException();
	}

	
	public <R, P> R accept(ElementVisitor<R, P> v, P p) {
		throw typeElementNotFoundException();
	}

	
	public <A extends Annotation> A[] getAnnotationsByType(Class<A> annotationType) {
		throw typeElementNotFoundException();
	}

	@Override
	public List<? extends Element> getEnclosedElements() {
		throw typeElementNotFoundException();
	}

	@Override
	public NestingKind getNestingKind() {
		throw typeElementNotFoundException();
	}

	@Override
	public Name getQualifiedName() {
		return new GenName(type.qualifiedName());
	}

	@Override
	public Name getSimpleName() {
		return new GenName(type.simpleName());
	}

	@Override
	public TypeMirror getSuperclass() {
		throw typeElementNotFoundException();
	}

	@Override
	public List<? extends TypeMirror> getInterfaces() {
		throw typeElementNotFoundException();
	}

	@Override
	public List<? extends TypeParameterElement> getTypeParameters() {
		throw typeElementNotFoundException();
	}

	@Override
	public Element getEnclosingElement() {
		// TODO Könnte man noch irgendwie retten
		throw typeElementNotFoundException();
	}

}
