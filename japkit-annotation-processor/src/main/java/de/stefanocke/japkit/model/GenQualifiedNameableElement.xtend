package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.QualifiedNameable
import de.stefanocke.japkit.activeannotations.Derived

@FieldsFromInterface
abstract class GenQualifiedNameableElement extends GenElement implements QualifiedNameable {
	@Derived
	override getQualifiedName(){
		new GenName('''«»(enclosingElement as QualifiedNameable)?.qualifiedName».«simpleName»''')
	}
	
	
}