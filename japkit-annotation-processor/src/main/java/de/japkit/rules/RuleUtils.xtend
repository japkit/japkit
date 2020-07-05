package de.japkit.rules

import de.japkit.annotations.AnnotationTemplate
import de.japkit.el.ELSupport
import de.japkit.metaannotations.Param
import de.japkit.metaannotations.Var
import de.japkit.model.AnnotationAndParent
import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenElement
import de.japkit.model.GenExtensions
import de.japkit.model.GenParameter
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import de.japkit.services.MessageCollector
import de.japkit.services.ReportedException
import de.japkit.rules.RuleException
import de.japkit.services.TypeElementNotFoundException
import de.japkit.services.TypesExtensions
import de.japkit.services.TypesRegistry
import de.japkit.util.MoreCollectionExtensions
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
import de.japkit.model.GenUnresolvedType

/** Many rules have common components, for example annotation mappings or setting modifiers. This class provides
 * those common components as reusable closures. Each one establishes as certain naming convention for the according
 * annotation values, for example "nameExpr" for the AV the contains an expression to determine the name of the element to be generated.
 */
class RuleUtils {
	val protected transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val protected transient extension ELSupport = ExtensionRegistry.get(ELSupport)
	val protected transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val protected transient extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	val protected transient extension GenExtensions = ExtensionRegistry.get(GenExtensions)
	val protected transient extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val protected transient extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val protected transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val protected transient extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val protected transient extension TypesRegistry typesRegistry = ExtensionRegistry.get(TypesRegistry)

	static def withPrefix(CharSequence name, String prefix) {
		(if(prefix.nullOrEmpty) name else { 
			if(Character.isLowerCase(prefix.charAt(prefix.length -1))) 
				'''«prefix»«name.toString.toFirstUpper»'''
				else '''«prefix»«name»'''
		}).toString
	}

	public static val ()=>Iterable<? extends Object> SINGLE_SRC_ELEMENT = [|
		Collections.singleton(ExtensionRegistry.get(ELSupport).currentSrc)
	]

	/**
	 * Provides the source element(s) for rules 
	 */
	def ()=>Object createSrcRule(AnnotationMirror metaAnnotation, String avPrefix) {
		createExpressionOrFunctionCallAndFilterRule(
			metaAnnotation,
			null,
			"src",
			"srcFun",
			"srcLang",
			"srcFilter",
			"srcFilterFun",
			"srcCollect",
			"srcCollectFun",
			"srcToSet",
			"srcGroupBy",
			"srcGroupByFun",
			"srcType",
			avPrefix,
			[|currentSrc],
			false,
			"srcUnique"
		)
	}

	/**
	 * Evaluates and expression and / or function(s) and optionally filters the results.
	 */
	def ()=>Object createExpressionOrFunctionCallAndFilterRule(
		AnnotationMirror metaAnnotation,
		Element metaElement,
		String exprAV,
		String funAV,
		String langAV,
		String filterExprAV,
		String filterFunAV,
		String collectExprAV,
		String collectFunAV,
		String toSetAV,
		String groupByAV,
		String groupByFunAV,
		String typeAV,
		String avPrefix,
		()=>Object defaultValue,
		boolean nullable,
		String uniqueAV
	) {
		if(metaAnnotation === null) return SINGLE_SRC_ELEMENT

		val type = metaAnnotation?.value(typeAV?.withPrefix(avPrefix), TypeMirror)

		val typeClass = if (type !== null) {
				Class.forName(type.asElement.qualifiedName.toString);
			} else
				Object

		val collectExprOrFunction = new ExpressionOrFunctionCallRule<Object>(metaAnnotation, metaElement, Object,
			collectExprAV, langAV, collectFunAV, avPrefix, null, nullable, null)

		val groupByExprOrFunction = new ExpressionOrFunctionCallRule<Object>(metaAnnotation, metaElement, Object,
			groupByAV, langAV, groupByFunAV, avPrefix, null, false, null)

		// TODO: Typecheck here does not make sense in case of collect !? 	
		val srcExprOrFunction = new ExpressionOrFunctionCallRule<Object>(metaAnnotation, metaElement, typeClass, exprAV,
			langAV, funAV, avPrefix, defaultValue, nullable, null)

		val srcFilterExprOrFunction = new ExpressionOrFunctionCallRule(metaAnnotation, metaElement, Boolean,
			filterExprAV, langAV, filterFunAV, avPrefix, null, false, ExpressionOrFunctionCallRule.AND_COMBINER);

		val toSet = metaAnnotation?.value(toSetAV, Boolean) ?: false;

		val unique = metaAnnotation?.value(uniqueAV, Boolean) ?: false;

		[|
			var srcElements = {
				val elements = srcExprOrFunction.apply()

				if (elements instanceof Iterable<?>) {
					elements
				} else if (elements !== null && elements.class.array) {
					Arrays.asList(elements)
				} else {
					elements
				}
			}

			if (srcElements instanceof Iterable<?>) {
				if (!srcFilterExprOrFunction.undefined) {
					srcElements = srcElements.filter [
						scope(it) [
							srcFilterExprOrFunction.apply ?: false
						]
					]
				}
				if (!collectExprOrFunction.undefined) {
					srcElements = (srcElements as Iterable<?>).map [
						scope(it) [
							collectExprOrFunction.apply
						]
					]
				}
				if (toSet) {
					srcElements = (srcElements as Iterable<?>).toSet
				}
				if (unique) {
					srcElements = MoreCollectionExtensions.singleValue(srcElements as Iterable<?>);
				}
				if (!groupByExprOrFunction.undefined) {
					srcElements = (srcElements as Iterable<?>).groupBy [
						scope(it) [
							groupByExprOrFunction.apply
						]
					]
				}

			}

			srcElements
		]
	}

	/**Scope rule that gets the source element from "src" AV */
	def <T> ScopeRule<T> createScopeRule(AnnotationMirror metaAnnotation, Element metaElement, String avPrefix) {
		createScopeRule(metaAnnotation, metaElement, false, avPrefix, true)
	}

	def <T> ScopeRule<T> createScopeRule(AnnotationMirror metaAnnotation, Element metaElement, boolean isLibrary,
		String avPrefix) {
		createScopeRule(metaAnnotation, metaElement, isLibrary, avPrefix, true)
	}

	def <T> ScopeRule<T> createScopeRule(AnnotationMirror metaAnnotation, Element metaElement, String avPrefix,
		()=>Object srcRule) {
		createScopeRule(metaAnnotation, metaElement, false, avPrefix, true)
	}

	/**Rule that creates a new scope for each src element given by the source rule and executes the given closure within that scope. 
	 * Optionally puts EL-Variables into that scope. 
	 */
	def <T> ScopeRule<T> createScopeRule(
		AnnotationMirror metaAnnotation,
		Element metaElement,
		boolean isLibrary,
		String avPrefix,
		boolean createSrcRule
	) {
		return new ScopeRule<T>(metaAnnotation, metaElement, isLibrary, avPrefix, createSrcRule)
	}

	def createLibraryRules(AnnotationMirror metaAnnotation, String avPrefix) {
		new ArrayList(metaAnnotation?.value("libraries".withPrefix(avPrefix), typeof(TypeMirror[]))?.map [
			createLibraryRule(it.asElement)
		] ?: emptyList)
	}

	ScopeRule<Object> SCOPE_WITH_CURRENT_SRC

	def ScopeRule scopeWithCurrentSrc() {
		if (SCOPE_WITH_CURRENT_SRC === null) {
			SCOPE_WITH_CURRENT_SRC = createScopeRule(null, null, null)
		}
		SCOPE_WITH_CURRENT_SRC
	}

	def createELVariableRules(AnnotationMirror metaAnnotation, Element metaElement, String avPrefix) {
		val rules = newArrayList();
		// Create VarRules from the "vars" AV
		rules.addAll(metaAnnotation?.value("vars".withPrefix(avPrefix), typeof(AnnotationMirror[]))?.map [
			new ELVariableRule(it, null)
		] ?: emptyList)

		// if the metaElement is a type element, search for members annotates with @Var and create variable rules for them
		if (metaElement instanceof TypeElement) {
			rules.addAll(
				metaElement.enclosedElementsOrdered.filter[isVariable].map[createFunctionRule(it)].filter [
					it instanceof ELVariableRule
				].map[it as ELVariableRule]
			)
		}

		rules
	}

	def boolean isVariable(Element memberElement) {
		memberElement.annotationMirror(Var) !== null
	}

	public static val ALWAYS_ACTIVE = [|true]

	def ()=>boolean createActivationRule(AnnotationMirror metaAnnotation, String avPrefix) {
		createActivationRule(metaAnnotation, avPrefix, [|true])
	}

	/**
	 * AV "cond" to enable or disable a rule
	 */
	def ()=>boolean createActivationRule(AnnotationMirror metaAnnotation, String avPrefix,
		()=>Boolean defaultValue) {

		val rule = new ExpressionOrFunctionCallRule<Boolean>(metaAnnotation, null, Boolean, "cond", "condLang",
			"condFun", avPrefix, defaultValue, false, ExpressionOrFunctionCallRule.AND_COMBINER);

		if(rule.undefined) null else rule
	}

	public static val NO_NAME = [|null as String]

	// There are some places in templates besides the meta-annotations where expressions or EL variables can be used:
	// - Names of elements (methods, fields, params, ...).  
	// - String annotation values
	// They have to be enclosed in $...$ there.
	// In element names, "." is not allowed, so "_" can be used instead and is replaced by "."
	static val expressionInTemplate = Pattern.compile('''\$(.+?)\$''')

	def replaceExpressionInTemplate(CharSequence template, boolean noSyntaxRestrictions, String lang,
		boolean autoCamelCase) {

		val vs = ExtensionRegistry.get(ELSupport).valueStack
		val matcher = expressionInTemplate.matcher(template)
		val sb = new StringBuffer();
		while (matcher.find()) {
			val expr = matcher.group(1)
			val value = if (expr == "srcElementName")
					// For backward compatibility
					currentSrcElement.simpleName.toString
				else {
					val exprToEvaluate = '''#{«if(noSyntaxRestrictions) expr else expr.replace('_','.')»}'''
					eval(exprToEvaluate, lang,
						CharSequence, null, expr)?.toString
				}
			matcher.appendReplacement(sb,
				if(autoCamelCase && matcher.start > 0 &&
					Character.isLowerCase(template.charAt(matcher.start - 1))) value.toFirstUpper else value);
		}
		matcher.appendTail(sb);
	}

	/**
	 * To set the name of the generated element either statically (AV: name) or dynamically (AV: nameExpr)
	 */
	def ()=>String createNameExprRule(AnnotationMirror metaAnnotation, Element template, String avPrefix) {
		val nameFromTemplate = template?.simpleName
		val name = metaAnnotation?.value("name".withPrefix(avPrefix), String)
		val nameExpr = metaAnnotation?.value("nameExpr".withPrefix(avPrefix), String)
		val nameLang = metaAnnotation?.value("nameLang".withPrefix(avPrefix), String);

		[|
			val nameFromTemplateResolved = nameFromTemplate?.replaceExpressionInTemplate(false, null, true)?.toString
			val result = if (!nameExpr.nullOrEmpty) {
					eval(nameExpr, nameLang, String, "nameExpr".withPrefix(avPrefix),
						nameFromTemplateResolved ?: 'invalidMemberName')
				} else if (!name.nullOrEmpty) {
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
	def (GenElement)=>List<? extends AnnotationMirror> createAnnotationMappingRules(
		AnnotationMirror metaAnnotation, Element template, String avPrefix) {

		val mappings = metaAnnotation?.annotationMappingRulesFromMetaAnnotation("annotations".withPrefix(avPrefix)) ?: newArrayList();
		mappings.addAll(annotationMappingRulesFromAnnotationTemplates(template));

		[ genElement |
			val annotations = new ArrayList(genElement.annotationMirrors.map [
				it as GenAnnotationMirror
			])
			// Copy all annotations from template element that are no japkit annotations and no AnnotationTemplate
			annotations.addAll(
				template?.copyAnnotations(
					[am|!am.isJapkitAnnotation && !am.hasMetaAnnotation(AnnotationTemplate.name)],
					templateAnnotationValueTransformer
				) ?: emptyList
			)

			//apply the annotation mapping rules. Modifies the annotations list passed in!
			mappings?.forEach[mapOrCopyAnnotations(annotations)]
			annotations
		]
	}

	private def List<AnnotationMappingRule> annotationMappingRulesFromAnnotationTemplates(Element templateElement) {
		templateElement?.annotationMirrors?.filter[hasMetaAnnotation(AnnotationTemplate.name)]?.map[new AnnotationMappingRule(
			//Wrap the annotation for rule error reporting. For "normal" meta-annotations, this is done in ElementExtensions.annotationMirror 
			new AnnotationAndParent(it, null, null, templateElement), 
			templateElement
		)]?.toList ?: emptyList
	}

	private def List<AnnotationMappingRule> annotationMappingRulesFromMetaAnnotation(AnnotationMirror metaAnnotation, CharSequence avName) {
		val result = newArrayList();
		// To refer to annotation rules from annotation value rules, the annotation rules are collected by id here and 
		// this map is passed through to the annotation value rules, so they can lazily get the annotation mappings
		val annotationMappingsById = newHashMap();
		metaAnnotation.value(avName, typeof(AnnotationMirror[]))?.forEach [
			val amr = new AnnotationMappingRule(it, annotationMappingsById)
			if (amr.id.nullOrEmpty) {
				// Only add "top-level" annotation mappings
				result.add(amr)
			} else {
				// Mappings with id are used from within annotation value mappings. Provide lookup for them via a map
				annotationMappingsById.put(amr.id, amr);
			}
		]
		result
	}

	private def List<GenAnnotationMirror> mapAnnotations(Iterable<? extends AnnotationMappingRule> mappings,
		List<GenAnnotationMirror> existingAnnotations) {

		val annotations = existingAnnotations
		mappings.forEach[mapOrCopyAnnotations(annotations)]
		annotations

	}

	// Transformer to be used when copying annotations from templates. Resolves types and evaluates expressions.
	public val static (Object)=>Object templateAnnotationValueTransformer = [
		if (it instanceof TypeMirror) {
			ExtensionRegistry.get(TypeResolver).resolveType(it)
		} else if (it instanceof String) {
			ExtensionRegistry.get(RuleUtils).replaceExpressionInTemplate(it, true, null, false)?.toString // TODO: make lang configurable
		} else {
			it
		}
	]

	def ()=>Set<Modifier> createModifiersRule(AnnotationMirror metaAnnotation, Element template,
		String avPrefix) {
		val templateModifiers = template?.modifiers ?: emptySet

		if(metaAnnotation === null) return [|template?.modifiers]
		val modi = metaAnnotation.value("modifiers".withPrefix(avPrefix), typeof(Modifier[]));
		val modifiersFromSrc = metaAnnotation.value("modifiersFromSrc".withPrefix(avPrefix), Boolean) ?: false;
		
		
		// conditions for whether to add or remove modifier
		val modifierConditions = #[Modifier.ABSTRACT, Modifier.PUBLIC, Modifier.PRIVATE, Modifier.PROTECTED].map [
			val name = it.toString.toLowerCase;
			it ->
				new ExpressionOrFunctionCallRule<Boolean>(metaAnnotation, template, Boolean, name + "Cond",
					name + "CondLang", name + "CondFun", null, null, false, ExpressionOrFunctionCallRule.AND_COMBINER)
		].filter[!it.value.undefined];  
		
		

		[|
			val modifiers = new HashSet(if (!modi.nullOrEmpty) {
				modi.toSet
			} else {
				templateModifiers
			});
			if (modifiersFromSrc) {
				modifiers.addAll(currentSrcElement.modifiers)
			}
			//if any modifier condition is set, evaluate it an add or remove the according modifier
			modifierConditions.forEach[
				if(it.value.apply) {
					modifiers.add(it.key)
				} else {
					modifiers.remove(it.key)
				}
			]
			
			modifiers
		]
	}

	def ()=>TypeMirror createTypeRule(AnnotationMirror metaAnnotation, TypeMirror template, String avPrefix) {
		createTypeRule(metaAnnotation, template, "type", avPrefix, [|currentSrcElement.srcType?.resolveType])
	}

	def ()=>TypeMirror createTypeRule(AnnotationMirror metaAnnotation, TypeMirror template, String avName,
		String avPrefix, ()=>TypeMirror defaultValue) {

		[|
			try {
				val type = metaAnnotation?.resolveTypeFromAnnotationValues(avName.withPrefix(avPrefix), '''«avName»Args'''.withPrefix(avPrefix))
				if (!type.isVoid) {
					type
				} else {
					if (template !== null) {
						template.resolveType ?: getNoType(TypeKind.NONE)
					} else
						defaultValue?.apply
				}
			} catch (TypeElementNotFoundException tenfe) {
				handleTypeElementNotFound('''TypeElement not found for «template?.simpleName ?: avName».''', tenfe.fqn);
				new GenUnresolvedType(tenfe.fqn, false)
			}
		]
	}

	def protected ()=>List<? extends GenParameter> createParamRules(AnnotationMirror paramsAnnotation,
		ExecutableElement template, String avPrefix) {
		val rules = if (template !== null) {
				// If there is a template, use its parameters. They can optionally have @Param annotation
				template.parametersWithSrcNames.map[createParamRule(it.annotationMirror(Param), it, null)].toList
			} else {
				// No template. Use the params from the @Method or @Constructor annotation
				paramsAnnotation.value("parameters".withPrefix(avPrefix), typeof(AnnotationMirror[])).map [
					createParamRule(it, null, null)
				].toList
			}

		[|rules.map[apply].flatten.toList]
	}

	def ()=>List<? extends GenParameter> createParamRule(AnnotationMirror paramAnnotation,
		VariableElement template, String avPrefix) {
		new ParamRule(paramAnnotation, template, avPrefix);

	}
	

	def ()=>CharSequence createCommentRule(AnnotationMirror metaAnnotation, Element template, String avPrefix,
		()=>CharSequence defaultComment) {
		val copyFromSrc = metaAnnotation?.value("commentFromSrc".withPrefix(avPrefix), Boolean) ?: false
		val commentExpr = metaAnnotation?.value("commentExpr".withPrefix(avPrefix), String)
		val commentLang = metaAnnotation?.value("commentLang".withPrefix(avPrefix), String);
		val commentFromTemplate = template?.getDocCommentUsingRuntimeMetadata.removeCode
		val expr = if(commentExpr.nullOrEmpty) commentFromTemplate else commentExpr;

		[|
			if (copyFromSrc)
				currentSrcElement.docComment
			else if (!expr.nullOrEmpty)
				eval(expr, commentLang, CharSequence, "commentExpr".withPrefix(avPrefix), 'invalidComment')
			else
				defaultComment?.apply
		]
	}

	// A predicate that checks whether a given name is amongst a set of names given by an expression
	def (CharSequence)=>boolean createNameInSetRule(AnnotationMirror metaAnnotation, String avName) {
		val expr = metaAnnotation?.value(avName, String)
		val lang = metaAnnotation?.value('''«avName»Lang''', String);

		if (expr.nullOrEmpty)
			null
		else
			[
				val nameSet = eval(expr, lang, Iterable, avName, emptySet).
					map [
						if (it instanceof Element) {
							it.simpleName.toString
						} else {
							it.toString // TODO: Das is etwas lax.
						}
					].toSet

				nameSet.contains(it.toString)

			]
	}

	/**
	 * Gets a list of element matchers from an annotation.
	 */
	def createMatcherRules(AnnotationMirror annotation, CharSequence avName) {
		val av = (annotation.value(avName, typeof(AnnotationMirror[])))
		if(av !== null) av.map[createMatcherRule(it)] else emptyList
	}

	/** 
	 * Catches Exceptions and reports them as errors for the current meta annotation.
	 * The AV name can be provided to report the error for that AV of the meta annotation.
	 * TODO: We have this in many places with subtle differences. Refactor for harmonization? 
	 * 
	 * <ul>
	 * <li>TypeElementNotFoundException is always rethrown, since they need to be handled in the the JapkitProcessor itself by deferring the code generation until the missing type becomes available.
	 * <li>ReportedException is rethrown, unless an errorResult is given. ReporteException means, that the Exception has always been reported to the MessageCollector and does not need to be handled again.
	 * <li>RuleException and other Exceptions are reported to the MessageCollector to be shown as error to the user later. In no errorResult is given, an ReportedException is thrown then.
	 * </ul>
	 * 
	 * The errors are reported for the current context (currently processed annotated class or package and meta-element / meta-annotation of the currently processed rule )
	 * 
	 * @param errorResult the function that supplies the result that should be returned in case of an error. To be used if it makes sense to continue code generation for the current element after the error. 
	 * @param avName optional. The name of the annotation value of the meta-annotation for which the error occurred or is related to.
	 * @param closure the code to be executed within the try-catch
	 * 
	 * @return the result from execution of the code or (in case of error) the errorResult
	 * 
	 */
	def <T> T handleException(()=>T errorResult, String avName, ()=>T closure) {
		try {
			closure.apply()
		} catch (TypeElementNotFoundException tenfe) {
			// Always rethrow TENFE (?)
			throw tenfe
		} catch (ReportedException e) {
			// Do not report the error again to avoid error flooding
			if(errorResult !== null) return errorResult.apply() else throw e
		} catch (Exception e) {
			reportRuleError(e, avName)
			if(errorResult !== null) return errorResult.apply() else throw new ReportedException(e)
		}
	}

}
