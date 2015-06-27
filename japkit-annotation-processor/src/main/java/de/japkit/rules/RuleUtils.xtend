package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.el.ElVariableError
import de.japkit.metaannotations.Param
import de.japkit.metaannotations.ResultVar
import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenElement
import de.japkit.model.GenExtensions
import de.japkit.model.GenParameter
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import de.japkit.services.MessageCollector
import de.japkit.services.TypeElementNotFoundException
import de.japkit.services.TypesExtensions
import java.util.ArrayList
import java.util.Arrays
import java.util.Collections
import java.util.HashSet
import java.util.List
import java.util.Set
import java.util.regex.Pattern
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror

import static extension de.japkit.rules.JavadocUtil.*
import de.japkit.services.ReportedException
import de.japkit.metaannotations.Var

/** Many rules have common components, for example annotation mappings or setting modifiers. This class provides
 * those common components as reusable closures. Each one establishes as certain naming convention for the according
 * annotation values, for example "nameExpr" for the AV the contains an expression to determine the name of the element to be generated.
 */
class RuleUtils {
	val protected transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val protected transient extension ELSupport = ExtensionRegistry.get(ELSupport)
	val protected transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val protected transient extension AnnotationExtensions  = ExtensionRegistry.get(AnnotationExtensions)
	val protected transient extension GenExtensions = ExtensionRegistry.get(GenExtensions)
	val protected transient extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val protected transient extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val protected transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val protected transient extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	
	
	public static def withPrefix(CharSequence name, String prefix){
		(if(prefix.nullOrEmpty) name else '''«prefix»«name.toString.toFirstUpper»''').toString
	}
	
	public static val ()=>Iterable<? extends Object> SINGLE_SRC_ELEMENT = [|  Collections.singleton(ExtensionRegistry.get(ELSupport).currentSrc)]
	
	/**
	 * Provides the source element(s) for rules 
	 */
	public def ()=>Object createSrcRule(AnnotationMirror metaAnnotation, String avPrefix) {
		createExpressionOrFunctionCallAndFilterRule(metaAnnotation, null, "src", "srcFun", "srcLang", 
			"srcFilter", "srcFilterFun", 
			"srcCollect", "srcCollectFun", 
			"srcType", avPrefix, [| currentSrc], false
		)
	}
	
	/**
	 * Evaluates and expression and / or function(s) and optionally filters the results.
	 */
	public def ()=>Object createExpressionOrFunctionCallAndFilterRule(AnnotationMirror metaAnnotation, Element metaElement,
		String exprAV, String funAV, String langAV, 
		String filterExprAV, String filterFunAV, 
		String collectExprAV, String collectFunAV, 
		String typeAV, String avPrefix,
		()=>Object defaultValue, boolean nullable
	) {
		if(metaAnnotation==null) return SINGLE_SRC_ELEMENT
		
		val type = metaAnnotation?.value(typeAV?.withPrefix(avPrefix), TypeMirror)
		
		val typeClass = if(type!=null){
			Class.forName(type.asElement.qualifiedName.toString);
		} else Object
		
		val collectExprOrFunction = new ExpressionOrFunctionCallRule<Object>(metaAnnotation, metaElement, Object, 
			collectExprAV, langAV, collectFunAV, avPrefix, null, nullable, null)
			
		//TODO: Typecheck here does not make sense in case of collect !? 	
		val srcExprOrFunction = new ExpressionOrFunctionCallRule<Object>(metaAnnotation, metaElement, typeClass, 
			exprAV, langAV, funAV, avPrefix, defaultValue, nullable, null)
			
		
		val srcFilterExprOrFunction = new ExpressionOrFunctionCallRule(metaAnnotation, metaElement, Boolean, 
			filterExprAV, langAV, filterFunAV, avPrefix, null, false, ExpressionOrFunctionCallRule.AND_COMBINER);

		[|
			var srcElements =  {
					val elements = srcExprOrFunction.apply()
					
					if(elements instanceof Iterable<?>){	
						elements				
					}
					else if(elements != null && elements.class.array) {
						Arrays.asList(elements)
					} 
					else {
						elements
					} 
				} 
			if(srcElements instanceof Iterable<?> && !srcFilterExprOrFunction.undefined){
				srcElements = (srcElements as Iterable<?>).filter[
					scope(it)[
						srcFilterExprOrFunction.apply ?: false
					]
				]
			}
			if(srcElements instanceof Iterable<?> && !collectExprOrFunction.undefined){
				srcElements = (srcElements as Iterable<?>).map[
					scope(it)[
						collectExprOrFunction.apply ?: false
					]
				]
			}
			srcElements
		]
	}
	
	/**Scope rule that gets the source element from "src" AV */
	public def <T> ((Object)=>T)=>List<T>  createScopeRule(AnnotationMirror metaAnnotation, Element metaElement, String avPrefix) {
		createScopeRule(metaAnnotation, metaElement, false, avPrefix, createSrcRule(metaAnnotation, avPrefix), true)
	}
	
	public def <T> ((Object)=>T)=>List<T>  createScopeRule(AnnotationMirror metaAnnotation, Element metaElement, boolean isLibrary, String avPrefix) {
		createScopeRule(metaAnnotation, metaElement, isLibrary, avPrefix, createSrcRule(metaAnnotation, avPrefix), true)
	}
	
	public def <T> ((Object)=>T)=>List<T>  createScopeRule(AnnotationMirror metaAnnotation, Element metaElement, String avPrefix, ()=>Object srcRule) {
		createScopeRule(metaAnnotation, metaElement, false, avPrefix, createSrcRule(metaAnnotation, avPrefix), true)	
	}
	/**Rule that creates a new scope for each src element given by the source rule and executes the given closure within that scope. 
	 * Optionally puts EL-Variables into that scope. 
	 */
	public def <T> ((Object)=>T)=>List<T>  createScopeRule(AnnotationMirror metaAnnotation, Element metaElement, boolean isLibrary, 
		String avPrefix, ()=>Object srcRule, boolean iterateIfIterable
	) {
			
		val srcVarName = metaAnnotation?.value("srcVar".withPrefix(avPrefix), String)
		val varRules = createELVariableRules(metaAnnotation, metaElement, avPrefix)
		val libraryRules = createLibraryRules(metaAnnotation, avPrefix)
		val selfLibrary = if(isLibrary) new LibraryRule(metaAnnotation, metaElement as TypeElement)
		
		val resultVarAnnotation = metaElement?.annotationMirror(ResultVar)		
		val resultVarAV =  resultVarAnnotation?.value("value".withPrefix(avPrefix), String);	
		val resultVarName = if(resultVarAV.nullOrEmpty) metaElement?.simpleName?.toString else resultVarAV;
			
		

		[(Object)=>T closure |
			try {
						
				val src = srcRule?.apply ?: currentSrc;
	
				val iterate = iterateIfIterable && src instanceof Iterable<?>		
				
				val result = if(iterate){ (src as Iterable<?>).map [ e |
						doInScope(e, srcVarName, libraryRules, selfLibrary, varRules, closure)
					].toList			
				}
				else{ 
					newArrayList(doInScope(src, srcVarName, libraryRules, selfLibrary, varRules, closure))				
				};	
				if(resultVarAnnotation!=null && !resultVarName.nullOrEmpty){
					valueStack.put(resultVarName, if(iterate) result else result.head)
				}
				
				result
			
			} catch (Exception e){
				//To avoid error flooding or misleading errors
				//TODO: Reconsider resultVar. Better use some functional approach + "mapping cache" instead
				if(resultVarAnnotation!=null && !resultVarName.nullOrEmpty){
					valueStack.put(resultVarName, new ElVariableError(resultVarName))
				}
				throw e
			}
		]
	}
	
	private def <T> T doInScope(Object src, String srcVarName, List<LibraryRule> libraryRules, LibraryRule selfLibrary, List<ELVariableRule> varRules, (Object)=>T closure) {
		scope(src) [
			if(!srcVarName.nullOrEmpty){valueStack.put(srcVarName, src)}
			libraryRules.forEach[apply]
			selfLibrary?.apply
			valueStack.put("currentRule", currentRule)
			varRules?.forEach[it.putELVariable]
			closure.apply(src)
		]
	}
	
	def createLibraryRules(AnnotationMirror metaAnnotation, String avPrefix) {
		metaAnnotation?.value("libraries".withPrefix(avPrefix), typeof(TypeMirror[]))?.map[createLibraryRule(it.asElement)] ?: emptyList
	}
	
	val SCOPE_WITH_CURRENT_SRC = createScopeRule(null, null, null)
	
	public def <T> ((Object)=>T)=>Iterable<T> scopeWithCurrentSrc(){		
		SCOPE_WITH_CURRENT_SRC	as ((Object)=>T)=>Iterable<T>
	}
	
	
	public def createELVariableRules(AnnotationMirror metaAnnotation, Element metaElement, String avPrefix){
		val rules = newArrayList();
		//Create VarRules from the "vars" AV
		rules.addAll(metaAnnotation?.value("vars".withPrefix(avPrefix), typeof(AnnotationMirror[]))?.map[new ELVariableRule(it, null)] ?: emptyList)
		
		//if the metaElement is a type element, search for members annotates with @Var and create variable rules for them
		if(metaElement instanceof TypeElement){
			rules.addAll(
				metaElement.enclosedElementsOrdered.filter[isVariable]
					.map[createFunctionRule(it)].filter[it instanceof ELVariableRule].map[it as ELVariableRule]
			)
		}
		
		rules
	}
	
	def boolean isVariable(Element memberElement) {
		memberElement.annotationMirror(Var) != null
	}
	
	public static val ALWAYS_ACTIVE = [| true]
	
	public def ()=>boolean createActivationRule(AnnotationMirror metaAnnotation, String avPrefix) {
		createActivationRule(metaAnnotation, avPrefix, [| true])
	}
	
	/**
	 * AV "cond" to enable or disable a rule
	 */
	public def ()=>boolean createActivationRule(AnnotationMirror metaAnnotation, String avPrefix, ()=>Boolean defaultValue) {

		val rule = new ExpressionOrFunctionCallRule<Boolean>(metaAnnotation, null, Boolean, 
		"cond", "condLang", "condFun", avPrefix, defaultValue , false, ExpressionOrFunctionCallRule.AND_COMBINER);
		
		if(rule.undefined) null else rule	
	}
	
	public static val NO_NAME = [|null as String]
	
	//There are some places in templates besides the meta-annotations where expressions or EL variables can be used:
	//- Names of elements (methods, fields, params, ...).  (only variables)
	//- String annotation values
	//They have to be enclosed in $...$ there.
	static val expressionInTemplate = Pattern.compile('''\$(.+?)\$''')
	
	public def replaceExpressionInTemplate(CharSequence template, boolean canBeExpression, String lang, boolean autoCamelCase) {
		
		val vs = ExtensionRegistry.get(ELSupport).valueStack
		val matcher = expressionInTemplate.matcher(template)
		val sb = new StringBuffer();
		while (matcher.find()) {
			val expr = matcher.group(1)
			val value = if (!canBeExpression) {

					//only variable names allowed, no expression
					if (expr == "srcElementName")
						currentSrcElement.simpleName.toString
					else {
						try{
							vs.get(expr)?.toString ?: {
								reportRuleError('''Variable «expr» in "«template»"" could not be resolved.''')
								expr
							}						
						} catch(ElVariableError e){
							//Do not report the error again here.
							expr
						}
					}
				} else {
					eval(expr, lang, String, '''Expression «expr» in "«template»"" could not be resolved.''', expr)
				}
			matcher.appendReplacement(sb, if(autoCamelCase && matcher.start>0) value.toFirstUpper else value);
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
			val nameFromTemplateResolved = nameFromTemplate?.replaceExpressionInTemplate(false, null, true)?.toString
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
				
		val mappings = metaAnnotation?.annotationMappings("annotations".withPrefix(avPrefix));
		
		[ genElement|
			val existingAnnotationsAndTemplateAnnotations = new ArrayList(genElement.annotationMirrors.map[it as GenAnnotationMirror])
			existingAnnotationsAndTemplateAnnotations.addAll(template?.copyAnnotations(isNoJapkitAnnotationFilter, templateAnnotationValueTransformer) ?: emptyList)
						
			if(mappings.nullOrEmpty) return existingAnnotationsAndTemplateAnnotations
			
			mapAnnotations(mappings, existingAnnotationsAndTemplateAnnotations)
		]
	}
	
	//Transformer to be used when copying annotations from templates. Resolves types and evaluates expressions.
	public val static (Object)=>Object templateAnnotationValueTransformer = [
		if(it instanceof TypeMirror){
			ExtensionRegistry.get(TypeResolver).resolveType(it)
		} else if(it instanceof String){
			ExtensionRegistry.get(RuleUtils).replaceExpressionInTemplate(it, true, null, false)?.toString //TODO: make lang configurable
		}  else {
			it
		}
	]
	
	 
	
	public def ()=>Set<Modifier> createModifiersRule(AnnotationMirror metaAnnotation, Element template, String avPrefix) {
		val templateModifiers = template?.modifiers ?: emptySet

		if(metaAnnotation == null) return [|template?.modifiers]
		val modi = metaAnnotation.value("modifiers".withPrefix(avPrefix), typeof(Modifier[]));
		val modifiersFromSrc = metaAnnotation.value("modifiersFromSrc".withPrefix(avPrefix), Boolean) ?: false;

		//TODO: Expressions for isPublic , isPrivate etc
		[ |
			val modifiers = new HashSet(
				if (!modi.nullOrEmpty) {
					modi.toSet
				} else {
					templateModifiers
				});
			if(modifiersFromSrc){
				modifiers.addAll(currentSrcElement.modifiers)
			}
			modifiers
		]
	}
	
	public def ()=>TypeMirror createTypeRule(AnnotationMirror metaAnnotation, TypeMirror template, String avPrefix) {
		createTypeRule(metaAnnotation, template, "type", avPrefix, [| currentSrcElement.srcType?.resolveType])
	}
	
	public def ()=>TypeMirror createTypeRule(AnnotationMirror metaAnnotation, TypeMirror template, String avName,
		String avPrefix, ()=>TypeMirror defaultValue) {

		[  |
			val type = metaAnnotation?.resolveType(avName.withPrefix(avPrefix), '''«avName»Args'''.withPrefix(avPrefix))
			if (!type.isVoid) {
				type
			} else {
				if(template != null){ template.resolveType ?: getNoType(TypeKind.NONE)} else defaultValue?.apply 
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
		
		val srcRule = createSrcRule(paramAnnotation, avPrefix)
		val scopeRule = createScopeRule(paramAnnotation, template, avPrefix, srcRule)
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
	
	//A predicate that checks whether a given name is amongst a set of names given by an expression
	def (CharSequence)=>boolean createNameInSetRule(AnnotationMirror metaAnnotation, String avName, boolean defaultResult){
		val expr = metaAnnotation?.value(avName, String)
		val lang = metaAnnotation?.value('''«avName»Lang''', String);
		
		if(expr.nullOrEmpty) [defaultResult] else
		[
			val nameSet = eval(expr, lang, Iterable, '''Name set expression could not be evaluated.''',
					emptySet).map[
						if(it instanceof Element){
							it.simpleName.toString
						} else {
							it.toString  //TODO: Das is etwas lax.
						}
					].toSet
					
			nameSet.contains(it.toString)
			
		]
	}
	
	//Catches Exceptions and reports them as errors for the current meta annotation.
	// The AV name can be provided to report the error for that AV of the meta annotation.
	// TODO: We have this in many places with subtle differences. Refactor for harmonization?
	def <T> T handleException(()=>T errorResult, String avName, ()=>T closure){
		try {
			closure.apply()
		} catch (TypeElementNotFoundException tenfe) {
			//Always rethrow TENFE (?)
			throw tenfe
		} catch(ReportedException e){
			//Do not report the error again to avoid error flooding
			if(errorResult != null) return errorResult.apply() else throw e
		} catch (Exception e) {
			reportRuleError(e, avName)
			if(errorResult != null) return errorResult.apply() else throw new ReportedException(e)
		}
	}
	
}