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
	
	new(AnnotationMirror metaAnnotation, String avPrefix){
		val prefix = if(avPrefix==null) "name" else avPrefix
		_regEx = metaAnnotation.value('''«prefix»RegEx''', Pattern)
		_regExReplace = metaAnnotation.value('''«prefix»RegExReplace''', String)		
		_expr =  metaAnnotation.value('''«prefix»Expr''', String)		
		_lang =  metaAnnotation.value('''«prefix»Lang''', String)		
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
			//The extra scoping for src element is required here since in ElementsExtensions.generatedTypeElementAccordingToTriggerAnnotation
			//the name of the generated class for a different annotated class than the current one is determined.
			//This has nevertheless some flaws, since there could be other context variables that were different when the other class has been generated.
			//Maybe, the typesRegistry could be used in generatedTypeElementAccordingToTriggerAnnotation instead of calculating the name? 
			scope(orgElement)[
				eval(expr, lang, String)			
			]
		} else {
			orgName.toString
		}
		
	}
}