package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.metaannotations.Param
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ELVariableRule
import java.util.ArrayList
import java.util.Arrays
import java.util.Collections
import java.util.List
import java.util.Set
import java.util.regex.Pattern
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

import static extension de.stefanocke.japkit.support.JavadocUtil.*

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
	val protected extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val protected extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val protected extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	
	
	public static def withPrefix(String name, String prefix){
		(if(prefix.nullOrEmpty) name else '''«prefix»«name.toFirstUpper»''').toString
	}
	
	public static val ()=>Iterable<? extends Object> SINGLE_SRC_ELEMENT = [|  Collections.singleton(ExtensionRegistry.get(ELSupport).currentSrc)]
	
	/**
	 * To iterate over a collection of elements and apply the rule for each element.
	 */
	public def ()=>Iterable<? extends Object> createSrcExpressionRule(AnnotationMirror metaAnnotation, String avPrefix) {
		if(metaAnnotation==null) return SINGLE_SRC_ELEMENT
		
		val srcExpr = metaAnnotation.value("src".withPrefix(avPrefix), String)
		val srcLang = metaAnnotation.value("srcLang".withPrefix(avPrefix), String);

		[|
			val srcElements = if (srcExpr.nullOrEmpty) {
					Collections.singleton(currentSrc) //Use parent's src. 
				} else {
					val elements = eval(srcExpr, srcLang, Object,
						'''Src expression «srcExpr» could not be evaluated''', emptyList)
						
					if(elements instanceof Iterable<?>){	
						elements				
					}
					else if(elements?.class.array) {
						Arrays.asList(elements)
					} 
					else {
						Collections.singleton(elements)
					} 
				} 
			srcElements
		]
	}
	
	/**Scope rule that gets the source element from "src" AV */
	public def <T> ((Object)=>T)=>Iterable<T>  createScopeRule(AnnotationMirror metaAnnotation, String avPrefix) {
		createScopeRule(metaAnnotation, avPrefix, createSrcExpressionRule(metaAnnotation, avPrefix))
	}
	
	/**Rule that creates a new scope for each src element given by the source rule and executes the given closure within that scope. 
	 * Optionally puts EL-Variables into that scope. 
	 */
	public def <T> ((Object)=>T)=>Iterable<T>  createScopeRule(AnnotationMirror metaAnnotation, String avPrefix, ()=>Iterable<? extends Object> srcRule) {
			
		val srcVarName = metaAnnotation?.value("srcVar".withPrefix(avPrefix), String)
		val varRules = createELVariableRules(metaAnnotation, avPrefix);

		[(Object)=>T closure |
			val srcElements = srcRule?.apply ?: Collections.singleton(currentSrcElement)	
			
				
			(srcElements ?: Collections.singleton(currentSrc)).map [ e |
				scope(e) [
					if(!srcVarName.nullOrEmpty){valueStack.put(srcVarName, e)}
					varRules?.forEach[it.putELVariable]
					closure.apply(e)
				]
			].toList
					
		]
	}
	
	val SCOPE_WITH_CURRENT_SRC = createScopeRule(null, null)
	
	public def <T> ((Object)=>T)=>Iterable<T> scopeWithCurrentSrc(){		
		SCOPE_WITH_CURRENT_SRC	as ((Object)=>T)=>Iterable<T>
	}
	
	
	public def createELVariableRules(AnnotationMirror metaAnnotation, String avPrefix){
		metaAnnotation?.value("vars".withPrefix(avPrefix), typeof(AnnotationMirror[]))?.map[new ELVariableRule(it)] ?: emptyList;
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
	
	//There are some places in templates besides the meta-annotations where expressions or EL variables can be used:
	//- Names of elements (methods, fields, params, ...).  (only variables)
	//- String annotation values
	//They have to be enclosed in $...$ there.
	static val expressionInTemplate = Pattern.compile('''\$(.+?)\$''')
	
	public def replaceExpressionInTemplate(CharSequence template, boolean canBeExpression, String lang) {
		
		val vs = ExtensionRegistry.get(ELSupport).valueStack
		val matcher = expressionInTemplate.matcher(template)
		val	sb = new StringBuffer();
		while (matcher.find()) {
			val expr = matcher.group(1)
			val value = if(!canBeExpression){
				//only variable names allowed, no expression
				if(expr=="srcElementName") currentSrcElement.simpleName.toString 
					else  vs.get(expr)?.toString ?: {
						reportError('''Variable «expr» in "«template»"" could not be resolved.''', null, null, null)
						expr
					}			
			} else {
				eval(expr, lang, String, '''Expression «expr» in "«template»"" could not be resolved.''', expr) 
			}
			matcher.appendReplacement(sb, value);
		}
		matcher.appendTail(sb);
	}
	
	/**
	 * To set the name of the generated element either statically (AV: name) or dynamically (AV: nameExpr)
	 */
	public def ()=>String createNameExprRule(AnnotationMirror metaAnnotation, Element template, String avPrefix) {
		val nameFromTemplate = template?.simpleName
		val name = metaAnnotation?.value("name".withPrefix(avPrefix), String)
		val nameExpr = metaAnnotation?.value("nameExpr".withPrefix(avPrefix), String)
		val nameLang = metaAnnotation?.value("nameLang".withPrefix(avPrefix), String);

		[ |
			val nameFromTemplateResolved = nameFromTemplate?.replaceExpressionInTemplate(false, null)?.toString
			val result = if (!nameExpr.nullOrEmpty) {
				eval(nameExpr, nameLang, String, '''Member name could not be generated''',
					nameFromTemplateResolved ?: 'invalidMemberName')
			} else if(!name.nullOrEmpty) {
				name
			} else {
				nameFromTemplateResolved
			}
			if(result.nullOrEmpty) currentSrcElement.simpleName.toString else result
		]
	}
	
	/**
	 * Copies annotations from template at first (if there are any ) and then applies the annotation mappings
	 */
	public def (GenElement)=>List<? extends AnnotationMirror> createAnnotationMappingRules(
		AnnotationMirror metaAnnotation, Element template, String avPrefix) {
				
		val mappings = metaAnnotation?.annotationMappings("annotations".withPrefix(avPrefix), null);
		
		[ genElement|
			val existingAnnotationsAndTemplateAnnotations = new ArrayList(genElement.annotationMirrors.map[it as GenAnnotationMirror])
			existingAnnotationsAndTemplateAnnotations.addAll(template?.copyAnnotations(isNoJapkitAnnotationFilter, GenExtensions.templateAnnotationValueTransformer) ?: emptyList)
						
			if(mappings.nullOrEmpty) return existingAnnotationsAndTemplateAnnotations
			
			mapAnnotations(mappings, existingAnnotationsAndTemplateAnnotations)
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
			val typeFromTemplate = template?.resolveType
			val type = metaAnnotation?.resolveType("type".withPrefix(avPrefix), "typeArgs".withPrefix(avPrefix))
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
		
		val srcRule = createSrcExpressionRule(paramAnnotation, avPrefix)
		val scopeRule = createScopeRule(paramAnnotation, avPrefix, srcRule)
		val nameRule = createNameExprRule(paramAnnotation, template, avPrefix)
		val annotationMappingRules = createAnnotationMappingRules(paramAnnotation, template,  avPrefix)
		val typeRule = createTypeRule(paramAnnotation, template?.asType, avPrefix);
		
		createParamRule(scopeRule, nameRule, typeRule, annotationMappingRules)

	}
	
	public def ()=>List<? extends GenParameter> createParamRule(()=>String nameRule, ()=>TypeMirror typeRule, (GenElement)=>List<? extends AnnotationMirror> annotationMappingRules) {
		createParamRule(scopeWithCurrentSrc, nameRule, typeRule, annotationMappingRules)
	
	}
	
	public def ()=>List<? extends GenParameter> createParamRule(((Object)=>GenParameter)=>Iterable<GenParameter> scopeRule, ()=>String nameRule, ()=>TypeMirror typeRule, (GenElement)=>List<? extends AnnotationMirror> annotationMappingRules) {
		
		[ |
			scopeRule.apply [
				val name = nameRule.apply
				val type = typeRule.apply
				
				val param = new GenParameter(name, type)
					
				if(annotationMappingRules!=null){	
					param.annotationMirrors = annotationMappingRules.apply(param)
				}
				param
			].toList
		]
	}
	
	def ()=>CharSequence createCommentRule(AnnotationMirror metaAnnotation, Element template, String avPrefix,
		()=>CharSequence defaultComment) {
		val copyFromSrc =  metaAnnotation?.value("commentFromSrc".withPrefix(avPrefix), Boolean) ?: false
		val commentExpr = metaAnnotation?.value("commentExpr".withPrefix(avPrefix), String)
		val commentLang = metaAnnotation?.value("commentLang".withPrefix(avPrefix), String);
		val commentFromTemplate = template?.docComment.removeCode
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