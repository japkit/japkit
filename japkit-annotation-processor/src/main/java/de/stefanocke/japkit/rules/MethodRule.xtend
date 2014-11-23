package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.GenElement
import de.stefanocke.japkit.model.GenExtensions
import de.stefanocke.japkit.model.GenMethod
import de.stefanocke.japkit.model.GenParameter
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.singleValue

@Data
class MethodRule extends ExecutableElementRule<GenMethod> {

	
	()=>TypeMirror returnTypeRule
	(GenMethod)=>AnnotationValue defaultAnnotationValueRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		returnTypeRule = createReturnTypeRule
		defaultAnnotationValueRule= createDefaultAnnotationValueRule
	}
	
	new(()=>boolean activationRule, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>Set<Modifier> modifiersRule,
		(GenElement)=>List<? extends AnnotationMirror> annotationsRule, ()=>CharSequence commentRule,
		()=>List<? extends GenParameter> paramRules, (GenMethod)=>CharSequence codeRule,
		()=>TypeMirror returnTypeRule) {
		super(activationRule, srcRule, nameRule, modifiersRule, annotationsRule, commentRule, paramRules, codeRule)
		this.returnTypeRule = returnTypeRule ?: [|null]
		defaultAnnotationValueRule=[m|null]
		
	}
	
	
	new(AnnotationMirror metaAnnotation, String avPrefix, ()=>Iterable<? extends Object> srcRule,
		()=>String nameRule, ()=>CharSequence commentRule, ()=>List<? extends GenParameter> paramRules, 
		(GenMethod)=>CharSequence codeRule, ()=>TypeMirror returnTypeRule) {
		super(metaAnnotation, avPrefix, srcRule, nameRule, commentRule, paramRules, codeRule)	
		this.returnTypeRule = returnTypeRule ?: [|null]
		defaultAnnotationValueRule= [m|null]
	}
	
	def (GenMethod)=>AnnotationValue createDefaultAnnotationValueRule() {
		val avFromTemplate = template?.defaultValue
		val avMapping = metaAnnotation?.value("defaultAnnotationValue", typeof(AnnotationMirror[]))?.map[new AnnotationValueMappingRule(it)]?.singleValue;
		[m|
			if (avMapping != null) {
				avMapping.mapAnnotationValue(null, m.returnType, null)
			} else if(avFromTemplate!=null) {
				GenExtensions.copy(avFromTemplate, GenExtensions.templateAnnotationValueTransformer)
			} else {
				null
			}
		]
	}
	
	def createReturnTypeRule() {
		createTypeRule(metaAnnotation, template?.returnType, "return")
	}

	protected override createMember(String name) {
		new GenMethod(name)
	}
	
	protected override applyRulesAfterCreation(GenMethod member) {
		super.applyRulesAfterCreation(member)
		member.returnType = returnTypeRule.apply
		member.defaultValue = defaultAnnotationValueRule.apply(member)
	}
	
	

	

}
