package de.stefanocke.japkit.support

import de.stefanocke.japkit.support.el.ELSupport
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.tools.Diagnostic.Kind

@Data
class ConstraintRule extends AbstractRule{
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension ELSupport = ExtensionRegistry.get(ELSupport)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	
	String expr
	String msg
	Kind msgKind
	String lang
	
	def validate(){
		
		val result = 
		handleTypeElementNotFound(true, '''Constraint «expr» could not be evaluated.''')[
			eval(expr, lang, Boolean, '''Constraint «expr» could not be evaluated''', true)
		]
		
		
		if(result == null || !result){
			reportMessage(msg, if(currentSrc instanceof Element) currentSrcElement, msgKind)
		}
	}
	
	new(AnnotationMirror am){
		super(am, null)
		_expr = am.value("expr", String)
		_msg = am.value("msg", String)
		_msgKind = am.value("msgKind", Kind)
		_lang = am.value("lang", String)
	}
}