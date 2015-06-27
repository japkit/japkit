package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ElVariableError
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1
import javax.lang.model.element.Element
import de.stefanocke.japkit.services.RuleException

@Data
class ELVariableRule extends AbstractRule implements Function1<Object, Object>,  Function0<Object> {
	 
	String name
	boolean ifEmpty
	()=>Object exprOrFunctionCallRule

	new(AnnotationMirror elVarAnnotation, Element metaElement) {
		super(elVarAnnotation, null)
		val nameFromAV = elVarAnnotation.value("name", String);
		name = if(nameFromAV.nullOrEmpty) metaElement?.simpleName?.toString?.toFirstLower else nameFromAV
		if(name.nullOrEmpty){
			throw new RuleException("Either the name annotation value mut be set or the @Var annotation must be used at a member of a class.");
		}
		
		ifEmpty = elVarAnnotation.value("ifEmpty", Boolean);
		
		val nullable = elVarAnnotation.value("nullable", Boolean) ?: false;
		
		exprOrFunctionCallRule = createExpressionOrFunctionCallAndFilterRule(metaAnnotation, metaElement,
			"expr", "fun", "lang", "filter", "filterFun", "collect", "collectFun", "type", null,
			[|currentSrc], nullable
		)
		
	}

	def void putELVariable() {
		
		val exisitingValue = valueStack.get(name)
		if(ifEmpty && exisitingValue!==null && !exisitingValue.emptyVar) return
		
		val value = handleException([| new ElVariableError(name) as Object], null)[
			eval(currentSrc)
		]
		valueStack.put(name, value)
			
	}
	
	def Object eval(Object src) {
		inRule[
			exprOrFunctionCallRule.apply
		]
	}

	override apply(Object p) {
		eval(p)
	}
	
	override apply() {
		eval(currentSrc)
	}
	
}
