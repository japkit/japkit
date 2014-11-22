package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import de.stefanocke.japkit.activeannotations.Required
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.AnnotationValueVisitor

@FieldsFromInterface
class GenAnnotationValue implements AnnotationValue {
	
	@Required
	Object value
	
	override <R, P> accept(AnnotationValueVisitor<R,P> v, P p) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
		
	
}