package de.stefanocke.japkit.support

import de.stefanocke.japkit.metaannotations.Properties
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror

@Data
class PropertyFilter {
	val extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)
	val extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val extension JavaBeansExtensions javaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val extension GenerateClassContext =  ExtensionRegistry.get(GenerateClassContext)

	TypeMirror sourceClass
	String[] includeNames
	List<ElementMatcher> includeRules
	List<ElementMatcher> excludeRules
	Properties.RuleSource ruleSource

	AnnotationMirror metaAnnotation;

	boolean fromFields;

	/**
	 * Property source is determined by AV "sourceClass"
	 */
	def List<Property> getFilteredProperties() {
		val propertySource = handleTypeElementNotFound(null,
			'''Could not find property source. No properties will be generated.''', currentAnnotatedClass ) [
			sourceClass.resolveType.asTypeElement
		]
		if (propertySource != null) {
			handleTypeElementNotFound(emptyList,
				'''Could not determine properties of source «propertySource.qualifiedName».''', currentAnnotatedClass ) [
				getFilteredProperties(propertySource)
			]
		} else
			emptyList
	}

	def List<Property> getFilteredProperties(TypeElement propertySource) {

		val properties = propertySource.properties(Object.name, fromFields)
		
		//TODO: Should be an expression.
		includeNames.forEach [
			if (!properties.exists[p|it.equals(p.name)]) {
				reportError('''Property with name «it» does not exist in source class.''', null, null,
					null)
			}
		]

		properties.filter [
			includeRules.exists[r|r.matches(getSourceElement(ruleSource))] || includeNames.contains(name)
		].filter[excludeRules.forall[r|!r.matches(getSourceElement(ruleSource))]].toList
	}

	new(AnnotationMirror metaAnnotation) {


		_metaAnnotation = metaAnnotation
		_sourceClass = metaAnnotation.value("sourceClass", TypeMirror)
		_includeNames = metaAnnotation.value("includeNames", typeof(String[]))
		_includeRules = metaAnnotation.value("includeRules", typeof(AnnotationMirror[])).map[
			createElementMatcher(it)]
		_excludeRules = metaAnnotation.value("excludeRules", typeof(AnnotationMirror[])).map[
			createElementMatcher(it)]
		_ruleSource = metaAnnotation.value("ruleSource", Properties.RuleSource)
		_fromFields = metaAnnotation.value("fromFields", Boolean)
	}
}
