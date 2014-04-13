package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.ExecutableElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenMethod extends GenExecutableElement implements ExecutableElement {
	public static val kind = METHOD

	

}
	
	
