package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ElVariableError
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

@Data
class ELVariableRule extends AbstractRule implements Function1<Object, Object>,  Function0<Object> {
	 
	String name
	boolean ifEmpty
	()=>Object exprOrFunctionCallRule

	new(AnnotationMirror elVarAnnotation) {
		super(elVarAnnotation, null)
		name = elVarAnnotation.value("name", String);
		
		ifEmpty = elVarAnnotation.value("ifEmpty", Boolean);
		
		val nullable = elVarAnnotation.value("nullable", Boolean) ?: false;
		
		exprOrFunctionCallRule = createExpressionOrFunctionCallAndFilterRule(metaAnnotation, 
			"expr", "fun", "lang", "filter", "filterFun", "type", null,
			[|currentSrc], [| new ElVariableError(name)], nullable
		)
		
	}

	def void putELVariable() {
		
		val exisitingValue = valueStack.get(name)
		if(ifEmpty && exisitingValue!==null && !exisitingValue.emptyVar) return
		
		val value = eval(currentSrc)
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
