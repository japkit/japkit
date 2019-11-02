package de.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.PackageElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.QualifiedNameable
import de.japkit.rules.RuleException

@Data
class ClassNameRule extends AbstractRule{
	String classSuffixToAppend
	String classSuffixToRemove
	String classPrefixToPrepend
	String classPrefixToRemove
	NameRule classNameRule
	NameRule packageNameRule
	
	def private String generateClassName(QualifiedNameable orgClass){
		//TODO: Special Handling if orgClass is Package
		val orgName = orgClass.simpleName.toString
		if(!(classNameRule.empty)){	
			return classNameRule.getName(orgName)
		}
		var name = orgName
		if(!classSuffixToRemove.nullOrEmpty){
			if(!name.endsWith(classSuffixToRemove)){
				throw new RuleException('''Naming rule violated: Name "«orgName»" must end with «classSuffixToRemove»''', "nameSuffixToRemove")
			}
			name = name.substring(0, name.length-classSuffixToRemove.length)
			if(name.empty){
				throw new RuleException('''Naming rule violated: Name "«orgName»" must not be empty after removing suffix «classSuffixToRemove»''', "nameSuffixToRemove")
			}
		}
		if(!classPrefixToRemove.nullOrEmpty){
			if(!name.startsWith(classPrefixToRemove)){
				throw new RuleException('''Naming rule violated: Name "«orgName»" must begin with «classPrefixToRemove»''', "namePrefixToRemove")
			}
			name = name.substring(classPrefixToRemove.length)
			if(name.empty){
				throw new RuleException('''Naming rule violated: Name "«orgName»" must not be empty after removing prefix «classPrefixToRemove»''', "namePrefixToRemove")
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
	
	def private String generatePackageName(PackageElement orgPackage){
		var name = orgPackage.qualifiedName.toString
		packageNameRule.getName(name)
	}
	
	def Pair<String,String> generateClassAndPackageName(QualifiedNameable orgClass){
		inRule[
			generatePackageName(orgClass.package)->generateClassName(orgClass)		
		]
	}
	
	def String generateQualifiedName(QualifiedNameable orgClass){
		val names = generateClassAndPackageName(orgClass)
		'''«names.key».«names.value»'''.toString
	}
	
	new (AnnotationMirror metaAnnotation){
		super(metaAnnotation, null)
		classSuffixToAppend = metaAnnotation.value("nameSuffixToAppend", String)
		classSuffixToRemove = metaAnnotation.value("nameSuffixToRemove", String)
		classPrefixToPrepend = metaAnnotation.value("namePrefixToPrepend", String)
		classPrefixToRemove = metaAnnotation.value("namePrefixToRemove", String)
		
		classNameRule = new NameRule(metaAnnotation, "name")
		packageNameRule = new NameRule(metaAnnotation, "packageName")	
		
	}
	
}