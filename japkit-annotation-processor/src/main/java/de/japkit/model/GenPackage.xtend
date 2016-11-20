package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import de.japkit.activeannotations.Required
import java.util.Map
import javax.lang.model.element.Name
import javax.lang.model.element.PackageElement

import static javax.lang.model.element.ElementKind.*

import static extension de.japkit.util.MoreCollectionExtensions.*

@FieldsFromInterface
class GenPackage extends GenElement implements PackageElement{
	public static val kind = PACKAGE	
	static val String simpleName_default = null
	
	@Required
	Name qualifiedName
	
	boolean unnamed
	
	static val Map<CharSequence, GenPackage> packageForName = newHashMap()
	
	new (CharSequence qualifiedName){
		super()
		setQualifiedName(new GenName(qualifiedName.toString))
	}
	
	def static packageForName(CharSequence qualifiedName){
		packageForName.getOrCreate(qualifiedName, [new GenPackage(qualifiedName)])
	}
	
}