package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.support.el.ELSupport
import java.util.ArrayList
import java.util.Collections
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

/** Many rules have common components, for example annotation mappings or setting modifiers. This class provides
 * those common components as reusable closures. Each one establishes as certain naming convention for the according
 * annotation values, for example "nameExpr" for the AV the contains an expression to determine the name of the element to be generated.
 */
class RuleUtils {
	val protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val protected extension ELSupport = ExtensionRegistry.get(ELSupport)
	val protected extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val protected extension AnnotationExtensions  = ExtensionRegistry.get(AnnotationExtensions)
	
	public static val (Element)=>Iterable<? extends Element> SINGLE_SRC_ELEMENT = [Element e |  Collections.singleton(e)]
	
	//If there are no annoation mappings, the annotations on the generated element are the ones from the template
	protected static val NO_ANNOTATION_MAPPINGS = [GenElement gen, Element src |  gen.annotationMirrors]
	
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
	
	/**
	 * To set the name of the generated element either statically (AV: name) or dynamically (AV: nameExpr)
	 */
	protected def (Object)=>String createNameExprRule(AnnotationMirror metaAnnotation) {
		if(metaAnnotation == null) return [null]
		val name = metaAnnotation.value("name", String)
		val nameExpr = metaAnnotation.value("nameExpr", String)
		val nameLang = metaAnnotation.value("nameLang", String);

		[
			if (!nameExpr.nullOrEmpty) {
				eval(valueStack, nameExpr, nameLang, String, '''Member name could not be generated''',
					'invalidMemberName')
			} else {
				name
			}
		]
	}
	
	// gen element (with annotations copied from template), src element => annotations
	protected def (GenElement, Element)=>List<? extends AnnotationMirror> createAnnotationMappingRules(
		AnnotationMirror metaAnnotation) {
		if(metaAnnotation==null) return NO_ANNOTATION_MAPPINGS
		val mappings = metaAnnotation.annotationMappings("annotationMappings", null);
		[ GenElement genElement, Element ruleSrcElement |
			mapAnnotations(ruleSrcElement, mappings,
				new ArrayList(genElement.annotationMirrors.map[it as GenAnnotationMirror]))
		]
	}
	
}