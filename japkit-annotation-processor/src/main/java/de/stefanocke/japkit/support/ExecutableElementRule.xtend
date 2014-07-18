package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenExecutableElement
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.metaannotations.Param
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

@Data
abstract class ExecutableElementRule<G extends GenExecutableElement> extends MemberRuleSupport<ExecutableElement, G> {

	
	(Element)=>List<? extends GenParameter> paramRules
	
	(G, Element)=>CodeBody codeBodyRule
	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		_paramRules = createParamRules
		_codeBodyRule = createCodeBodyRule 
	}
	
	protected override applyRulesAfterCreation(G member, Element ruleSrcElement) {
		super.applyRulesAfterCreation(member, ruleSrcElement)
		member.parameters = _paramRules.apply(ruleSrcElement)
		member.body = _codeBodyRule.apply(member, ruleSrcElement)
	}
	
	def protected (G, Element)=>CodeBody createCodeBodyRule(){
		val cr = new CodeRule(metaAnnotation, "body");
		[G genElement, Element ruleSourceElement | cr.getAsCodeBody(genElement)]
	}
	
	
	def protected (Element)=>List<? extends GenParameter>  createParamRules(){
		val rules= if(template !=null){
			//If there is a template, use its parameters. They can optionally have @Param annotation
			template.parametersWithSrcNames.map[createParamRule(it.annotationMirror(Param), it)].toList
		} else {
			//No template. Use the params from the @Method or @Constructor annotation
			metaAnnotation.value("parameters", typeof(AnnotationMirror[])).map[createParamRule(it, null)].toList
		}
		
		[ Element ruleSrcElement | rules.map[apply(ruleSrcElement)].flatten.toList ]
	}
	
	protected def (Element)=>Iterable<? extends GenParameter> createParamRule(AnnotationMirror paramAnnotation, VariableElement template){
		val srcElementsRule = ru.createIteratorExpressionRule(paramAnnotation, null)
		val nameRule = ru.createNameExprRule(paramAnnotation, template, null)
		val annotationMappingRules = ru.createAnnotationMappingRules(paramAnnotation, template, null)
		val typeRule = ru.createTypeRule(paramAnnotation, template?.asType, null);
		
		createParamRule(srcElementsRule, nameRule, typeRule, annotationMappingRules)

	}
	
	protected def createParamRule((Element)=>Iterable<? extends Element> srcElementsRule, (Object)=>String nameRule, (Element)=>TypeMirror typeRule, (Element)=>List<? extends AnnotationMirror> annotationMappingRules) {
		[ Element ruleSrcElement |
			srcElementsRule.apply(ruleSrcElement).map [ e |
				valueStack.scope(e) [
					val name = nameRule.apply(e)
					val type = typeRule.apply(e)
					
					val param = new GenParameter(name, type)
						
					param.annotationMirrors = annotationMappingRules.apply(e)
					param
				]
			]
		]
	}
	
	
}