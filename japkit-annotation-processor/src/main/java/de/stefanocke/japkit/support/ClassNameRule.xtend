package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.PackageElement
import javax.lang.model.element.TypeElement

@Data
class ClassNameRule {
	String classSuffixToAppend
	String classSuffixToRemove
	String classPrefixToPrepend
	String classPrefixToRemove
	NameRule classNameRule
	NameRule packageNameRule
	
	val extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)
	
	def String generateClassName(TypeElement orgClass){
		val orgName = orgClass.simpleName.toString
		if(!(classNameRule.empty)){	
			return classNameRule.getName(orgName, orgClass)
		}
		var name = orgName
		if(!classSuffixToRemove.nullOrEmpty){
			if(!name.endsWith(classSuffixToRemove)){
				throw new ProcessingException('''Naming rule violated: Name "«orgName»" must end with «classSuffixToRemove»''', orgClass)
			}
			name = name.substring(0, name.length-classSuffixToRemove.length)
			if(name.empty){
				throw new ProcessingException('''Naming rule violated: Name "«orgName»" must not be empty after removing suffix «classSuffixToRemove»''', orgClass)
			}
		}
		if(!classPrefixToRemove.nullOrEmpty){
			if(!name.startsWith(classPrefixToRemove)){
				throw new ProcessingException('''Naming rule violated: Name "«orgName»" must begin with «classPrefixToRemove»''', orgClass)
			}
			name = name.substring(classPrefixToRemove.length)
			if(name.empty){
				throw new ProcessingException('''Naming rule violated: Name "«orgName»" must not be empty after removing prefix «classPrefixToRemove»''', orgClass)
			}
		}
		
		if(!classSuffixToAppend.nullOrEmpty){
			name = name + classSuffixToAppend
		}
		if(!classPrefixToPrepend.nullOrEmpty){
			name = classPrefixToPrepend + name
		}
		name
	}
	
	def String generatePackageName(PackageElement orgPackage){
		var name = orgPackage.qualifiedName.toString
		packageNameRule.getName(name, orgPackage)
	}
	
	def String generateQualifiedName(TypeElement orgClass){
		'''«generatePackageName(orgClass.package)».«generateClassName(orgClass)»'''.toString
	}
	
	new (AnnotationMirror am, AnnotationMirror metaAnnotation){
		//this(suffixToAppend, suffixToRemove, prefixToPrepend, prefixToRemove, regEx, regExReplace, packageRegEx, packageRegExReplace)
		
		_classSuffixToAppend = am.valueOrMetaValue("nameSuffixToAppend", String, metaAnnotation)
		_classSuffixToRemove = am.valueOrMetaValue("nameSuffixToRemove", String, metaAnnotation)
		_classPrefixToPrepend = am.valueOrMetaValue("namePrefixToPrepend", String, metaAnnotation)
		_classPrefixToRemove = am.valueOrMetaValue("namePrefixToRemove", String, metaAnnotation)
		
		_classNameRule = new NameRule(am, metaAnnotation, "name")
		_packageNameRule = new NameRule(am, metaAnnotation, "packageName")	
		
	}
	
}