package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.support.el.ELSupport
import java.util.Collections
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.gen.GenElement

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
	
	public static val (Element)=>Iterable<? extends Element> SINGLE_SRC_ELEMENT = [Element e |  Collections.singleton(e)]
	
	/**
	 * To iterate over a collection of elements and apply the rule for each element.
	 */
	public def (Element)=>Iterable<? extends Element> createIteratorExpressionRule(AnnotationMirror metaAnnotation) {
		if(metaAnnotation==null) return SINGLE_SRC_ELEMENT
		
		val iteratorExpr = metaAnnotation.value("iterator", String)
		val iteratorLang = metaAnnotation.value("iteratorLang", String);

		[Element ruleSrcElement|
			val srcElements = if (iteratorExpr.nullOrEmpty) {
					Collections.singleton(ruleSrcElement)
				} else {
					eval(ruleSrcElement, iteratorExpr, iteratorLang, Iterable,
						'''Iterator expression «iteratorExpr» could not be evaluated''', emptyList).
						filterInstanceOf(Element)
				} 
			srcElements
		]
	}
	
	public static val ALWAYS_ACTIVE = [Element e | true]
	/**
	 * AV "activation" to enable or disable a rule
	 */
	public def (Element)=>boolean createActivationRule(AnnotationMirror metaAnnotation) {

		val activation = metaAnnotation?.elementMatchers("activation", null)
		if(activation.nullOrEmpty) return ALWAYS_ACTIVE;

		[Element ruleSrcElement|activation.exists[matches(ruleSrcElement)]]
	}
	
	public static val NO_NAME = [null as String]
	
	/**
	 * To set the name of the generated element either statically (AV: name) or dynamically (AV: nameExpr)
	 */
	public def (Object)=>String createNameExprRule(AnnotationMirror metaAnnotation, Element template) {
		val nameFromTemplate = template?.simpleName?.toString
		if(metaAnnotation == null) return [nameFromTemplate]
		val name = metaAnnotation.value("name", String)
		val nameExpr = metaAnnotation.value("nameExpr", String)
		val nameLang = metaAnnotation.value("nameLang", String);

		[
			if (!nameExpr.nullOrEmpty) {
				eval(valueStack, nameExpr, nameLang, String, '''Member name could not be generated''',
					nameFromTemplate ?: 'invalidMemberName')
			} else if(!name.nullOrEmpty) {
				name
			} else {
				nameFromTemplate
			}
		]
	}
	
	/**
	 * Copies annotations from template at first (if there are any ) and then applies the annotation mappings
	 */
	public def (Element)=>List<? extends AnnotationMirror> createAnnotationMappingRules(
		AnnotationMirror metaAnnotation, Element template) {
		
		
		if(metaAnnotation==null) return [e | template?.copyAnnotations ?: newArrayList]
		val mappings = metaAnnotation.annotationMappings("annotationMappings", null);
		
		[ Element ruleSrcElement |
			val annotationsFromTemplate = template?.copyAnnotations ?: newArrayList;
			mapAnnotations(ruleSrcElement, mappings, annotationsFromTemplate)
		]
	}
	
	public def (Object)=>Set<Modifier> createModifiersRule(AnnotationMirror metaAnnotation, Element template) {
		val templateModifiers = template?.modifiers ?: emptySet

		if(metaAnnotation == null) return [template?.modifiers]
		val modi = metaAnnotation.value("modifiers", typeof(Modifier[]));

		//TODO: Expressions for isPublic , isPrivate etc
		[
			if (!modi.nullOrEmpty) {
				modi.toSet
			} else
				templateModifiers
		]
	}
	
	//TODO: AV-overriding überdenken. 
	public def (Element)=>TypeMirror createTypeRule(AnnotationMirror metaAnnotation, TypeMirror template,
		String avPrefix) {

		[ Element ruleSrcElement |
			val typeFromTemplate = template?.relatedType(currentAnnotatedClass, currentGeneratedClass, currentAnnotation,
				null, ruleSrcElement)
			if(metaAnnotation == null) return typeFromTemplate
			val type = currentAnnotation.resolveType(currentAnnotatedClass, currentGeneratedClass, metaAnnotation,
				"type".withPrefix(avPrefix), "typeArgs".withPrefix(avPrefix), ruleSrcElement)
			if (!type.isVoid) {
				type
			} else {
				typeFromTemplate
			}
		]
	}
	
	public static def <R, E extends GenElement> andAssignResult((Element)=>R rule, (E, R)=>void setter){
		[E genElement, Element ruleSrcElement |
			val result = rule.apply(ruleSrcElement)
			setter.apply(genElement, result)
		]
	}
	
}