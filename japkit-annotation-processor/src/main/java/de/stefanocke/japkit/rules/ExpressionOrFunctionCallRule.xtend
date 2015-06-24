package de.stefanocke.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.Element
import de.stefanocke.japkit.services.RuleException
import static extension de.stefanocke.japkit.rules.RuleUtils.withPrefix

/** At several places in meta annotations it is possible to either directly use an expression or to refer to a function to be called. */
@Data
class ExpressionOrFunctionCallRule<T> extends AbstractFunctionRule<T> {
	
	String exprAvName
	String functionAvName
	String expr
	String lang
	TypeElement[] functionClasses
	()=>T defaultValue  //The value to be used if neither the expression nor the function is set
	(boolean, Object, IParameterlessFunctionRule<?>)=>Object combiner //Calls the funtion and combines the result with the previous one
	boolean nullable //whether the result or any of the intermediate results might be null
	
	new(AnnotationMirror metaAnnotation, Element metaElement, Class<? extends T> type, String exprAvName, String langAvName, String functionAvName, String avPrefix,
		()=>T defaultValue, ()=>T errorValue, boolean nullable, (boolean, Object, IParameterlessFunctionRule<?>)=>Object combiner 
	) {
		//TODO: Q&D: metaElement is null here, since we don't want the "params" feature of the superclass
		//Maybe the superclass is just not the appropriate one here ...
		super(metaAnnotation, null, type, errorValue) 
	
		this.exprAvName = exprAvName.withPrefix(avPrefix)
		this.functionAvName = functionAvName.withPrefix(avPrefix)
		
		val exprFromAv = metaAnnotation?.value(this.exprAvName, String)	;	
		this.expr = if(!exprFromAv.nullOrEmpty) exprFromAv else JavadocUtil.getCode(metaElement?.getDocCommentUsingRuntimeMetadata)?.get(exprAvName)
		
		this.lang = metaAnnotation?.value(langAvName.withPrefix(avPrefix), String)
		this.functionClasses = metaAnnotation?.value(this.functionAvName, typeof(TypeElement[]))	
		this.defaultValue = defaultValue
		this.nullable = nullable
		this.combiner = combiner ?: FLUENT_COMBINER
	}
	
	//Combiner that concatenates the function calls in a fluent way. At first, the expression is evaluated (if not empty). 
	//For the result, the first function is applied. For its result, the second function is applied. And so on.
	public static val (boolean, Object, IParameterlessFunctionRule<?>)=>Object FLUENT_COMBINER 
		= [isFirst, previous, function | if(isFirst) function.apply() else function.apply(previous)  ]
	
	//Combiner for boolean functions. Applies a logical AND. 	
	public static val (boolean, Object, IParameterlessFunctionRule<?>)=>Object AND_COMBINER 
		= [isFirst, previous, function | (if(isFirst) true else previous as Boolean) && {
			val r = function.apply
			if(!(r instanceof Boolean)){
				throw new RuleException('''The function returned «r» of type «r?.class», but the required type is Boolean''');
			} 
			r as Boolean}
		]
	
	//true if neither an expression nor a function is set and if no default value has been provided
	def boolean isUndefined() {
		expr.nullOrEmpty && functionClasses.nullOrEmpty && defaultValue == null
	}
	
	override evalInternal(){ 
		if(isUndefined){
			throw new RuleException('''Either «exprAvName» or «functionAvName» must be set or «metaElement» must be a function.''')	
		}
		
		val UNDEFINED = new Object()
		
		val exprResult = if(!expr.nullOrEmpty){
			handleException(null, exprAvName)[
				checkNotNull(eval(expr, lang, type, true))									
			]
		} else UNDEFINED
		
		if(exprResult==null) return null;
				
		val result = if (!functionClasses.nullOrEmpty) handleException(null, functionAvName) [
			var r = exprResult
			for (functionClass : functionClasses) {
				val function = functionClass?.createFunctionRule ?: metaElement?.createFunctionRule
				if (function == null) {
					throw new RuleException('''«functionClass» is not a function.''');
				}
				try{
					r = checkNotNull(combiner.apply(r == UNDEFINED, r, function))	
					if(r==null) return null; //Don't call further functions		
				} catch (Exception e){
					throw new RuleException('''Error when calling function «functionClass»: «e.message»''');
				}
			}
			if(!type.isInstance(r)) {
				throw new RuleException('''The function «functionClasses.last» returned «r» of type «r?.class», but the required type is «type»''')
			}
			r
		] else exprResult
				
		if(result == UNDEFINED){
			return defaultValue.apply()
		}
		
		result as T
		

	}
	
	def <V> checkNotNull(V value) {
		if(value == null && !nullable)throw new RuleException("The result is null. This is not allowed here.")		
		value
	}

}