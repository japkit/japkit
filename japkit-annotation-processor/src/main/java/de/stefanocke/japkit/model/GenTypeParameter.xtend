package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import java.util.List
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.TypeParameterElement
import javax.lang.model.type.TypeMirror

@FieldsFromInterface
class GenTypeParameter extends GenElement implements TypeParameterElement {
	public static val kind = ElementKind.TYPE_PARAMETER
	
	TypeMirror typeVariable;
	List<TypeMirror> bounds = newArrayList() 
	//Element enclosingElement
	Element genericElement
	
	override getEnclosingElement(){
		genericElement
	}
	override setEnclosingElement(Element e){
		genericElement = e
	}
	
	/**
	 * Copy-Constructor. 
	 */
	new (TypeParameterElement original, Element genericEl){
		this(original.simpleName)
		bounds.addAll(original.bounds)
		genericElement = genericEl
		//TODO: Das ist nicht so ganz korrekt... (Siehe Erläuterung in GenTypeElement)
		typeVariable = original.asType
	}
	
	override asType(){
		typeVariable
	}
}