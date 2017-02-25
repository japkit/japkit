package de.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.tools.Diagnostic.Kind
import org.eclipse.xtend.lib.annotations.Data

//TODO: Move this into srcRule to allow constraints at all places where a new child context is entered
@Data
class ConstraintRule extends AbstractRule{
	
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
			
			
			if(result === null || !result){
				reportMessage(msg, if(currentSrc instanceof Element) currentSrcElement, msgKind)
			}
			null
		]
	}
	
	new(AnnotationMirror am){
		super(am, null)
		expr = am.value("expr", String)
		msg = am.value("msg", String)
		msgKind = am.value("msgKind", Kind)
		lang = am.value("lang", String)
	}
}