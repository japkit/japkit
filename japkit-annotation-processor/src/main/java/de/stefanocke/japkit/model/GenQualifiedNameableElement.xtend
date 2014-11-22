package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.Derived
import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.QualifiedNameable

@FieldsFromInterface
abstract class GenQualifiedNameableElement extends GenElement implements QualifiedNameable {
	@Derived
	override getQualifiedName(){
		new GenName('''«»(enclosingElement as QualifiedNameable)?.qualifiedName».«simpleName»''')
	}
	
	
}