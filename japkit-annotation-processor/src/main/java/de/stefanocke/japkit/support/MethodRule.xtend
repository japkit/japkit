package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenParameter
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.type.TypeMirror

@Data
class MethodRule extends ExecutableElementRule<GenMethod> {

	
	()=>TypeMirror returnTypeRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		_returnTypeRule = createReturnTypeRule
	}
	
	new(()=>boolean activationRule, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>Set<Modifier> modifiersRule,
		(GenElement)=>List<? extends AnnotationMirror> annotationsRule, ()=>CharSequence commentRule,
		()=>List<? extends GenParameter> paramRules, (GenMethod)=>CharSequence codeRule,
		()=>TypeMirror returnTypeRule) {
		super(activationRule, srcRule, nameRule, modifiersRule, annotationsRule, commentRule, paramRules, codeRule)
		_returnTypeRule = returnTypeRule ?: [|null]
	}
	
	
	new(AnnotationMirror metaAnnotation, String avPrefix, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>CharSequence commentRule, ()=>List<? extends GenParameter> paramRules, 
		(GenMethod)=>CharSequence codeRule, ()=>TypeMirror returnTypeRule) {
		super(metaAnnotation, avPrefix, srcRule, nameRule, commentRule, paramRules, codeRule)	
		_returnTypeRule = returnTypeRule ?: [|null]
	}
	
	def createReturnTypeRule() {
		ru.createTypeRule(metaAnnotation, template?.returnType, "return")
	}

	protected override createMember(String name) {
		new GenMethod(name)
	}
	
	protected override applyRulesAfterCreation(GenMethod member) {
		super.applyRulesAfterCreation(member)
		member.returnType = returnTypeRule.apply
	}
	
	

	

}
