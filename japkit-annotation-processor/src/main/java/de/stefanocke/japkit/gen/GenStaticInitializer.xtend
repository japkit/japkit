package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.ExecutableElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenStaticInitializer extends GenExecutableElement implements ExecutableElement{
	public static val kind = STATIC_INIT
	
	public static val simpleName_default = "<clinit>"
	
}