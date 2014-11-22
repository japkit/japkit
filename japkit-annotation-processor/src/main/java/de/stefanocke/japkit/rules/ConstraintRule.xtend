package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ELSupport
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.tools.Diagnostic.Kind
import org.eclipse.xtend.lib.Data

@Data
class ConstraintRule extends AbstractRule{
	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension ELSupport = ExtensionRegistry.get(ELSupport)
	val transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	
	String expr
	String msg
	Kind msgKind
	String lang
	
	def void validate(){
		
		inRule[
			val result = 
			handleTypeElementNotFound(true, '''Constraint «expr» could not be evaluated.''')[
				eval(expr, lang, Boolean, '''Constraint «expr» could not be evaluated''', true)
			]
			
			
			if(result == null || !result){
				reportMessage(msg, if(currentSrc instanceof Element) currentSrcElement, msgKind)
			}
			null
		]
	}
	
	new(AnnotationMirror am){
		super(am, null)
		_expr = am.value("expr", String)
		_msg = am.value("msg", String)
		_msgKind = am.value("msgKind", Kind)
		_lang = am.value("lang", String)
	}
}