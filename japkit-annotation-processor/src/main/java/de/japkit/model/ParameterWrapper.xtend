package de.japkit.model

import java.lang.annotation.Annotation
import javax.lang.model.element.ElementVisitor
import javax.lang.model.element.Name
import javax.lang.model.element.VariableElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.ExecutableElement

@Data
class ParameterWrapper extends GenAnnotatedConstruct implements VariableElement {
	//We also remember the ExecutableElement, since for constructor parameters this is null in Eclipse (at least up to Neon).
	ExecutableElement enclosing
	
	int index;
	VariableElement delegate;
	Name name;
	
	override getConstantValue() {
		delegate.constantValue
	}
	
	override <R,P> accept(ElementVisitor<R, P> v, P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override asType() {
		delegate.asType
	}
	
	override <A extends Annotation> getAnnotation(Class<A> annotationType) {
		delegate.getAnnotation(annotationType)
	}
	
	override getAnnotationMirrors() {
		delegate.annotationMirrors
	}
	
	override getEnclosedElements() {
		delegate.enclosedElements
	}
	
	override getEnclosingElement() {
		enclosing
	}
	
	override getKind() {
		delegate.kind
	}
	
	override getModifiers() {
		delegate.modifiers
	}
	
	override getSimpleName() {
		if(name !== null) name else delegate.simpleName
	}
	
}