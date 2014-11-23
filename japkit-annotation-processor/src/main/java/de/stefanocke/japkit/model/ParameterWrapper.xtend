package de.stefanocke.japkit.model

import java.lang.annotation.Annotation
import javax.lang.model.element.ElementVisitor
import javax.lang.model.element.Name
import javax.lang.model.element.VariableElement
import org.eclipse.xtend.lib.annotations.Data

@Data
class ParameterWrapper implements VariableElement {
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
		delegate.enclosingElement
	}
	
	override getKind() {
		delegate.kind
	}
	
	override getModifiers() {
		delegate.modifiers
	}
	
	override getSimpleName() {
		if(name!=null) name else delegate.simpleName
	}
	
}