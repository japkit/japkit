package de.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.Element
import de.japkit.services.RuleException
import static extension de.japkit.rules.RuleUtils.withPrefix
import org.eclipse.xtext.xbase.lib.Functions.Function0

/** At several places in meta annotations it is possible to either directly use an expression or to refer to a function to be called. */
@Data
class ExpressionOrFunctionCallRule<T> extends AbstractRule implements Function0<T> {
	
	String exprAvName
	String functionAvName
	String expr
	String lang
	TypeElement[] functionClasses
	()=>T defaultValue  //The value to be used if neither the expression nor the function is set
	(boolean, Object, IParameterlessFunctionRule<?>)=>Object combiner //Calls the funtion and combines the result with the previous one
	boolean nullable //whether the result or any of the intermediate results might be null
	Class<? extends T> type
	
	new(AnnotationMirror metaAnnotation, Element metaElement, Class<? extends T> type, String exprAvName, String langAvName, String functionAvName, String avPrefix,
		()=>T defaultValue, boolean nullable, (boolean, Object, IParameterlessFunctionRule<?>)=>Object combiner 
	) {
		super(metaAnnotation, metaElement)
		this.exprAvName = exprAvName.withPrefix(avPrefix)
		this.functionAvName = functionAvName.withPrefix(avPrefix)
		
		val exprFromAv = metaAnnotation?.value(this.exprAvName, String)	;	
		this.expr = if(!exprFromAv.nullOrEmpty) exprFromAv else JavadocUtil.getCode(metaElement?.getDocCommentUsingRuntimeMetadata)?.get(exprAvName)
		
		this.lang = metaAnnotation?.value(langAvName.withPrefix(avPrefix), String)
		this.functionClasses = metaAnnotation?.value(this.functionAvName, typeof(TypeElement[])) 		 
		this.defaultValue = defaultValue
		this.nullable = nullable
		this.combiner = combiner ?: FLUENT_COMBINER
		this.type = type
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
		
	//Combiner for boolean functions. Applies a logical OR. 	
	public static val (boolean, Object, IParameterlessFunctionRule<?>)=>Object OR_COMBINER 
		= [isFirst, previous, function | (if(isFirst) false else previous as Boolean) || {
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
	
	override apply(){ 
		inRule[
			if(isUndefined){
				throw new RuleException('''Either «exprAvName» or «functionAvName» must be set.''')	
			}
			
			val UNDEFINED = new Object()
			
			val exprResult = if(!expr.nullOrEmpty){
				handleException(null, exprAvName)[
					checkNotNull(eval(expr, lang, type, true))									
				]
			} else UNDEFINED
			
			if(exprResult==null) return null;
			
			val functionRules = if (!functionClasses.nullOrEmpty) functionClasses.map[
				val function = createFunctionRule
				if (function == null) {
						throw new RuleException('''«it» is not a function.''');
					}
				function
			] 
			else emptyList
					
			val result = if (!functionRules.nullOrEmpty) handleException(null, functionAvName) [
				var r = exprResult
				for (function : functionRules) {
					try{
						r = checkNotNull(combiner.apply(r == UNDEFINED, r, function))	
						if(r==null) return null; //Don't call further functions		
					} catch (Exception e){
						throw new RuleException('''Error when calling function «function?.metaElement?.simpleName»: «e.message»''');
					}
				}
				if(!type.isInstance(r)) {
					throw new RuleException('''The function «functionRules.last?.metaElement?.simpleName» returned «r» of type «r?.class», but the required type is «type»''')
				}
				r
			] else exprResult
					
			if(result == UNDEFINED){
				return defaultValue.apply()
			}
			
			result as T	
		]
		
	}
	
	def <V> checkNotNull(V value) {
		if(value == null && !nullable)throw new RuleException("The result is null. This is not allowed here.")		
		value
	}

}