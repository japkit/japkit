package de.japkit.model

import de.japkit.activeannotations.Derived
import de.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.QualifiedNameable

@FieldsFromInterface
abstract class GenQualifiedNameableElement extends GenElement implements QualifiedNameable {
	@Derived
	override getQualifiedName(){
		new GenName('''«»(enclosingElement as QualifiedNameable)?.qualifiedName».«simpleName»''')
	}
	
	
}