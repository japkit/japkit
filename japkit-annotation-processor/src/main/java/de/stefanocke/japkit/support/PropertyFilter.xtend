package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror
import de.stefanocke.japkit.metaannotations.Properties
import java.util.List
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.gen.GenTypeElement

@Data
class PropertyFilter {
	val extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)
	val extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val extension JavaBeansExtensions javaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension TypeResolver relatedTypes = ExtensionRegistry.get(TypeResolver)

	String[] includeNames
	List<ElementMatcher> includeRules
	List<ElementMatcher> excludeRules
	Properties.RuleSource ruleSource

	AnnotationMirror am;
	AnnotationMirror metaAnnotation;

	boolean fromFields;

	/**
	 * Property source is determined by AV "sourceClass"
	 */
	def List<Property> getFilteredProperties(TypeElement annotatedClass, GenTypeElement generatedClass) {
		val propertySource = handleTypeElementNotFound(null,
			'''Could not find property source for «annotatedClass». No properties will be generated.''', annotatedClass) [
			resolveType(metaAnnotation, "sourceClass")?.asTypeElement
		]
		if (propertySource != null) {
			handleTypeElementNotFound(emptyList,
				'''Could not determine properties of source «propertySource.qualifiedName».''', annotatedClass) [
				getFilteredProperties(propertySource)
			]
		} else
			emptyList
	}

	def List<Property> getFilteredProperties(TypeElement propertySource) {

		val properties = propertySource.properties(Object.name, fromFields)
		includeNames.forEach [
			if (!properties.exists[p|it.equals(p.name)]) {
				reportError('''Property with name «it» does not exist in source class.''', null, am,
					metaAnnotation.getPrefixedAvName("includeNames"))
			}
		]

		properties.filter [
			includeRules.exists[r|r.matches(getSourceElement(ruleSource))] || includeNames.contains(name)
		].filter[excludeRules.forall[r|!r.matches(getSourceElement(ruleSource))]].toList
	}

	new(AnnotationMirror annotation, AnnotationMirror metaAnnotation) {

		_am = annotation
		_metaAnnotation = metaAnnotation
		_includeNames = annotation.valueOrMetaValue("includeNames", typeof(String[]), metaAnnotation)
		_includeRules = annotation.valueOrMetaValue("includeRules", typeof(AnnotationMirror[]), metaAnnotation).map[
			createElementMatcher(it)]
		_excludeRules = annotation.valueOrMetaValue("excludeRules", typeof(AnnotationMirror[]), metaAnnotation).map[
			createElementMatcher(it)]
		_ruleSource = annotation.valueOrMetaValue("ruleSource", Properties.RuleSource, metaAnnotation)
		_fromFields = annotation.valueOrMetaValue("fromFields", Boolean, metaAnnotation)
	}
}
