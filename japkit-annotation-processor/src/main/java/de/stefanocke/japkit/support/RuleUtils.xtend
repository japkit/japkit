package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.support.el.ELSupport
import java.util.Collections
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*
import javax.lang.model.element.ExecutableElement
import de.stefanocke.japkit.metaannotations.Param
import de.stefanocke.japkit.gen.GenElement
import java.util.ArrayList
import de.stefanocke.japkit.gen.GenAnnotationMirror

/** Many rules have common components, for example annotation mappings or setting modifiers. This class provides
 * those common components as reusable closures. Each one establishes as certain naming convention for the according
 * annotation values, for example "nameExpr" for the AV the contains an expression to determine the name of the element to be generated.
 */
class RuleUtils {
	val protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val protected extension ELSupport = ExtensionRegistry.get(ELSupport)
	val protected extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val protected extension AnnotationExtensions  = ExtensionRegistry.get(AnnotationExtensions)
	val protected extension GenExtensions = ExtensionRegistry.get(GenExtensions)
	val protected extension RelatedTypes relatedTypes = ExtensionRegistry.get(RelatedTypes)
	val protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	
	
	public static def withPrefix(String name, String prefix){
		(if(prefix.nullOrEmpty) name else '''«prefix»«name.toFirstUpper»''').toString
	}
	
	public static val ()=>Iterable<? extends Object> SINGLE_SRC_ELEMENT = [|  Collections.singleton(ExtensionRegistry.get(ELSupport).currentSrc)]
	
	/**
	 * To iterate over a collection of elements and apply the rule for each element.
	 */
	public def ()=>Iterable<? extends Object> createIteratorExpressionRule(AnnotationMirror metaAnnotation, String avPrefix) {
		if(metaAnnotation==null) return SINGLE_SRC_ELEMENT
		
		val iteratorExpr = metaAnnotation.value("iterator".withPrefix(avPrefix), String)
		val iteratorLang = metaAnnotation.value("iteratorLang".withPrefix(avPrefix), String);

		[|
			val srcElements = if (iteratorExpr.nullOrEmpty) {
					Collections.singleton(currentSrc)
				} else {
					val elements = eval(iteratorExpr, iteratorLang, Object,
						'''Iterator expression «iteratorExpr» could not be evaluated''', emptyList)
						
					if(elements instanceof Iterable<?>){	
						(elements as Iterable<?>).filterInstanceOf(Element)					
					} else {
						Collections.singleton(elements)
					} 
				} 
			srcElements
		]
	}
	
	public static val ALWAYS_ACTIVE = [| true]
	/**
	 * AV "activation" to enable or disable a rule
	 */
	public def ()=>boolean createActivationRule(AnnotationMirror metaAnnotation, String avPrefix) {

		val activation = metaAnnotation?.elementMatchers("activation".withPrefix(avPrefix), null)
		if(activation.nullOrEmpty) return ALWAYS_ACTIVE;

		[|activation.exists[matches(currentSrcElement)]]
	}
	
	public static val NO_NAME = [|null as String]
	
	/**
	 * To set the name of the generated element either statically (AV: name) or dynamically (AV: nameExpr)
	 */
	public def ()=>String createNameExprRule(AnnotationMirror metaAnnotation, Element template, String avPrefix) {
		val nameFromTemplate = template?.simpleName?.toString
		if(metaAnnotation == null) return [|nameFromTemplate]
		val name = metaAnnotation.value("name".withPrefix(avPrefix), String)
		val nameExpr = metaAnnotation.value("nameExpr".withPrefix(avPrefix), String)
		val nameLang = metaAnnotation.value("nameLang".withPrefix(avPrefix), String);

		[ |
			val result = if (!nameExpr.nullOrEmpty) {
				eval(nameExpr, nameLang, String, '''Member name could not be generated''',
					nameFromTemplate ?: 'invalidMemberName')
			} else if(!name.nullOrEmpty) {
				name
			} else {
				if(nameFromTemplate=="srcElementName") currentSrcElement.simpleName.toString else nameFromTemplate
			}
			if(result.nullOrEmpty) currentSrcElement.simpleName.toString else result
		]
	}
	
	/**
	 * Copies annotations from template at first (if there are any ) and then applies the annotation mappings
	 */
	public def (GenElement)=>List<? extends AnnotationMirror> createAnnotationMappingRules(
		AnnotationMirror metaAnnotation, Element template, String avPrefix) {
				
		val mappings = metaAnnotation?.annotationMappings("annotationMappings".withPrefix(avPrefix), null);
		
		[ genElement|
			val existingAnnotationsAndTemplateAnnotations = new ArrayList(genElement.annotationMirrors.map[it as GenAnnotationMirror])
			existingAnnotationsAndTemplateAnnotations.addAll(template?.copyAnnotations ?: emptyList)
						
			if(mappings.nullOrEmpty) return existingAnnotationsAndTemplateAnnotations
			
			mapAnnotations(currentSrcElement, mappings, existingAnnotationsAndTemplateAnnotations)
		]
	}
	
	 
	
	public def ()=>Set<Modifier> createModifiersRule(AnnotationMirror metaAnnotation, Element template, String avPrefix) {
		val templateModifiers = template?.modifiers ?: emptySet

		if(metaAnnotation == null) return [|template?.modifiers]
		val modi = metaAnnotation.value("modifiers".withPrefix(avPrefix), typeof(Modifier[]));

		//TODO: Expressions for isPublic , isPrivate etc
		[|
			if (!modi.nullOrEmpty) {
				modi.toSet
			} else
				templateModifiers
		]
	}
	
	//TODO: AV-overriding überdenken. 
	public def ()=>TypeMirror createTypeRule(AnnotationMirror metaAnnotation, TypeMirror template,
		String avPrefix) {

		[  |
			val typeFromTemplate = template?.relatedType(currentAnnotatedClass, currentGeneratedClass, currentAnnotation,
				null, currentSrcElement)
			if(metaAnnotation == null) return typeFromTemplate
			val type = currentAnnotation.resolveType(currentAnnotatedClass, currentGeneratedClass, metaAnnotation,
				"type".withPrefix(avPrefix), "typeArgs".withPrefix(avPrefix), currentSrcElement)
			if (!type.isVoid) {
				type
			} else {
				typeFromTemplate ?: currentSrcElement.srcType
			}
		]
	}
	
	def protected ()=>List<? extends GenParameter>  createParamRules(AnnotationMirror paramsAnnotation, ExecutableElement template, String avPrefix){
		val rules= if(template !=null){
			//If there is a template, use its parameters. They can optionally have @Param annotation
			template.parametersWithSrcNames.map[createParamRule(it.annotationMirror(Param), it, null)].toList
		} else {
			//No template. Use the params from the @Method or @Constructor annotation
			paramsAnnotation.value("parameters".withPrefix(avPrefix), typeof(AnnotationMirror[])).map[createParamRule(it, null, null)].toList
		}
		
		[ | rules.map[apply].flatten.toList ]
	}
	
	public def ()=>List<? extends GenParameter> createParamRule(AnnotationMirror paramAnnotation, VariableElement template, String avPrefix){
		val srcRule = createIteratorExpressionRule(paramAnnotation, avPrefix)
		val nameRule = createNameExprRule(paramAnnotation, template, avPrefix)
		val annotationMappingRules = createAnnotationMappingRules(paramAnnotation, template,  avPrefix)
		val typeRule = createTypeRule(paramAnnotation, template?.asType, avPrefix);
		
		createParamRule(srcRule, nameRule, typeRule, annotationMappingRules)

	}
	
	public def ()=>List<? extends GenParameter> createParamRule(()=>Iterable<? extends Object> srcRule, ()=>String nameRule, ()=>TypeMirror typeRule, (GenElement)=>List<? extends AnnotationMirror> annotationMappingRules) {
		[ |
			(srcRule ?: SINGLE_SRC_ELEMENT).apply.map [ e |
				scope(e) [
					val name = nameRule.apply
					val type = typeRule.apply
					
					val param = new GenParameter(name, type)
						
					if(annotationMappingRules!=null){	
						param.annotationMirrors = annotationMappingRules.apply(param)
					}
					param
				]
			].toList
		]
	}
	
	def ()=>CharSequence createCommentRule(AnnotationMirror metaAnnotation, Element template, String avPrefix,
		()=>CharSequence defaultComment) {
		val copyFromSrc =  metaAnnotation?.value("commentFromSrc".withPrefix(avPrefix), Boolean) ?: false
		val commentExpr = metaAnnotation?.value("commentExpr".withPrefix(avPrefix), String)
		val commentLang = metaAnnotation?.value("commentLang".withPrefix(avPrefix), String);
		val commentFromTemplate = template?.docComment
		val expr = if(commentExpr.nullOrEmpty) commentFromTemplate else commentExpr;

		[ |
			if(copyFromSrc) currentSrcElement.docComment
			else if (!expr.nullOrEmpty)
				eval(expr, commentLang, CharSequence, '''Comment could not be generated''',
					'invalidComment')
			else
				defaultComment?.apply
		]
	}
	
}