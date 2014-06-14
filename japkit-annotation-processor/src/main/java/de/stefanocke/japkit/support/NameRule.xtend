package de.stefanocke.japkit.support

import java.util.regex.Pattern
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import de.stefanocke.japkit.support.el.ELSupport

@Data
class NameRule {
	Pattern regEx
	String regExReplace
	String expr
	String lang

	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension ELSupport = ExtensionRegistry.get(ELSupport)
	
	new(AnnotationMirror am, AnnotationMirror metaAnnotation, String avPrefix){
		val prefix = if(avPrefix==null) "name" else avPrefix
		_regEx = am.valueOrMetaValue('''«prefix»RegEx''', Pattern, metaAnnotation)
		_regExReplace = am.valueOrMetaValue('''«prefix»RegExReplace''', String, metaAnnotation)		
		_expr =  am.valueOrMetaValue('''«prefix»Expr''', String, metaAnnotation)		
		_lang =  am.valueOrMetaValue('''«prefix»Lang''', String, metaAnnotation)		
	}
	
	def isEmpty(){
		regEx == null && expr == null
	}
		
	def String getName(CharSequence orgName, Element orgElement){
		if(regEx != null){
		
			val matcher = regEx.matcher(orgName)
			
			if(!matcher.matches){
				throw new ProcessingException('''Naming rule violated: Name "«orgName»" must match pattern "«regEx.pattern»"''', orgElement)
			}
			try{
				val name =  matcher.replaceFirst(regExReplace)	
				if(name.empty){
					throw new ProcessingException('''Naming rule violated: Name "«orgName»" must not be empty after replacing with "«regExReplace»"''', orgElement)
				}
				return name
			} catch (RuntimeException e){
				throw new ProcessingException('''Exception when replacing RegEx "«regEx.pattern»" with "«regExReplace»": «e.message»''', orgElement)
			}
		
		} else if(!expr.nullOrEmpty) {
			eval(orgElement, expr, lang, String)
		} else {
			orgName.toString
		}
		
	}
}