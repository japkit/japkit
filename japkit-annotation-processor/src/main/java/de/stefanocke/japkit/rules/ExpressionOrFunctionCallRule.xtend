package de.stefanocke.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.Element

/** At several places in meta annotations it is possible to either directly use an expression or to refer to a function to be called. */
@Data
class ExpressionOrFunctionCallRule<T> extends AbstractFunctionRule<T> {
	
	String exprAvName
	String functionAvName
	String expr
	String lang
	()=>Object function
	()=>T defaultValue
	
	new(AnnotationMirror metaAnnotation, Element metaElement, Class<T> type, String exprAvName, String langAvName, String functionAvName, ()=>T defaultValue) {
		super(metaAnnotation, metaElement, type)
	
		this.exprAvName = exprAvName
		this.functionAvName = functionAvName
		expr = metaAnnotation.value(exprAvName, String)	
		lang = metaAnnotation.value(langAvName, String)
		val functionClass = metaAnnotation.value(functionAvName, TypeElement)
		
		function = functionClass?.createFunctionRule ?: metaElement?.createFunctionRule
		this.defaultValue = defaultValue
	}
	
	override evalInternal(){ 
		if(!expr.nullOrEmpty){
			eval(expr, lang, type, true)
		} else if(function != null) {
			val result = function.apply()
			if(!type.isInstance(result)){
				reportRuleError('''The function «function» returned «result» of type «result?.class», but the required type is «type»''')
			}
			result as T
		} else if(defaultValue != null){
			defaultValue.apply()
		} else {
			//TODO: Move this check to constructor but still provide proper error msg location
			reportRuleError('''Either «exprAvName» or «functionAvName» must be set or «metaElement» must be a function.''')
			null
		}
	}

}