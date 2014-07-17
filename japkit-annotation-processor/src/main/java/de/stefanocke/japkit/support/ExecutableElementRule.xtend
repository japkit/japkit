package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenExecutableElement
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.metaannotations.Param
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.VariableElement
import de.stefanocke.japkit.gen.CodeBody

@Data
abstract class ExecutableElementRule<G extends GenExecutableElement> extends MemberRuleSupport<ExecutableElement, G> {

	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		
		addAfterCreationRule(createParamRules(metaAnnotation, template)) [ee, params| ee.parameters = params]
		addAfterCreationRule(createCodeBodyRuleWithAssignment)
	}
	
	def protected (G, Element)=>void createCodeBodyRuleWithAssignment(){
		val cbr = createCodeBodyRule();
		[G genElement, Element ruleSourceElement | 
			val codeBody = cbr.apply(genElement, ruleSourceElement)
			if (codeBody != null) { 
				genElement.removeModifier(Modifier.ABSTRACT)
				genElement.body = codeBody
			}
		]
	}
	
	def protected (G, Element)=>CodeBody createCodeBodyRule(){
		val cr = new CodeRule(metaAnnotation, "body");
		[G genElement, Element ruleSourceElement | cr.getAsCodeBody(genElement)]
	}
	
	
	def protected (Element)=>List<? extends GenParameter>  createParamRules(AnnotationMirror metaAnnotation, ExecutableElement template){
		val rules= if(template !=null){
			//If there is a template, use its parameters. They can optionally have @Param annotation
			template.parametersWithSrcNames.map[createParamRule(it.annotationMirror(Param), it)].toList
		} else {
			//No template. Use the params from the @Method or @Constructor annotation
			metaAnnotation.value("parameters", typeof(AnnotationMirror[])).map[createParamRule(it, null)].toList
		}
		
		[ Element ruleSrcElement | rules.map[apply(ruleSrcElement)].flatten.toList ]
	}
	
	def protected (Element)=>Iterable<? extends GenParameter> createParamRule(AnnotationMirror paramAnnotation, VariableElement template){
		val srcElementsRule = ru.createIteratorExpressionRule(paramAnnotation)
		val nameRule = ru.createNameExprRule(paramAnnotation, template)
		val annotationMappingRules = ru.createAnnotationMappingRules(paramAnnotation, template)
		val typeRule = ru.createTypeRule(paramAnnotation, template?.asType, null);
		
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