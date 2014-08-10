package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.TypeElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenAnnotationType extends GenTypeElement implements TypeElement{
	public static val kind = ANNOTATION_TYPE
}