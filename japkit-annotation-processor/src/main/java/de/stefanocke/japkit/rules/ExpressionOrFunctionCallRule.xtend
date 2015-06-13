package de.stefanocke.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.Element
import de.stefanocke.japkit.services.RuleException

/** At several places in meta annotations it is possible to either directly use an expression or to refer to a function to be called. */
@Data
class ExpressionOrFunctionCallRule<T> extends AbstractFunctionRule<T> {
	
	String exprAvName
	String functionAvName
	String expr
	String lang
	TypeElement functionClass
	()=>T defaultValue  //The value to be used if neither the expression nor the function is set
	()=>T errorValue  //The value to be used if an exception is catched
	
	new(AnnotationMirror metaAnnotation, Element metaElement, Class<T> type, String exprAvName, String langAvName, String functionAvName, 
		()=>T defaultValue, ()=>T errorValue
	) {
		super(metaAnnotation, metaElement, type)
	
		this.exprAvName = exprAvName
		this.functionAvName = functionAvName
		expr = metaAnnotation.value(exprAvName, String)	
		lang = metaAnnotation.value(langAvName, String)
		this.functionClass = metaAnnotation.value(functionAvName, TypeElement)
		
		
		this.defaultValue = defaultValue
		this.errorValue = errorValue
	}
	
	override evalInternal(){ 
		if(!expr.nullOrEmpty){
			handleException(errorValue, exprAvName)[
				eval(expr, lang, type, true)			
			]
		} else if(functionClass != null) {			
			handleException(errorValue, functionAvName)[
				val function = functionClass?.createFunctionRule ?: metaElement?.createFunctionRule
				if(function==null){
					throw new RuleException('''«functionClass» is not a function.''');
				}
				val result = function.apply()
				if(!type.isInstance(result)){
					throw new RuleException('''The function «functionClass» returned «result» of type «result?.class», but the required type is «type»''')
				}
				result as T		
			]
		} else if(defaultValue != null){
			defaultValue.apply()
		} else {
			//TODO: Move this check to constructor but still provide proper error msg location?
			throw new RuleException('''Either «exprAvName» or «functionAvName» must be set or «metaElement» must be a function.''')			
		}
	}

}