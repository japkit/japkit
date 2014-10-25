package de.stefanocke.japkit.support

import de.stefanocke.japkit.metaannotations.Properties
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.support.el.ELSupport
import java.util.Collection

@Data
class PropertyFilter {
	val extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)
	val extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val extension JavaBeansExtensions javaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val extension GenerateClassContext =  ExtensionRegistry.get(GenerateClassContext)
	val extension ELSupport = ExtensionRegistry.get(ELSupport)

	TypeMirror sourceClass
	String includeNamesExpr
	String includeNamesLang
	String includeNamesPrefix 
	String includeNamesSuffix 
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
		
		val includeNames = if(includeNamesExpr.nullOrEmpty) emptyList 
			else eval(includeNamesExpr, includeNamesLang, Collection, '''IncludeNamesExpr could not be evaluated: «includeNamesExpr»''', emptyList).
			map[
				//support for using (inner) classes to refer to properties.
				//Reason: Eclipse always returns "unknown" if the class containig a string constant is not available when used in an annotation value.
				//For class typed AVs we at least get the simple name of the class.
				//TODO: Support nested paths for deep traversing?  
				if(it instanceof TypeMirror) it.asTypeElement.simpleName.toString().toFirstLower else it as String
			].map[
				it.substring(includeNamesPrefix.length, it.length - includeNamesSuffix.length)
			].toList
		
		includeNames.forEach [
			if (!properties.exists[p|it.equals(p.name)]) {
				reportRuleError('''Property with name «it» does not exist in source class.''')
			}
		]

		properties.filter [
			includeRules.exists[r|r.matches(getSourceElement(ruleSource))] || includeNames.contains(name)
		].filter[excludeRules.forall[r|!r.matches(getSourceElement(ruleSource))]].toList
	}

	new(AnnotationMirror metaAnnotation) {


		_metaAnnotation = metaAnnotation
		_sourceClass = metaAnnotation.value("sourceClass", TypeMirror)
		_includeNamesExpr = metaAnnotation.value("includeNamesExpr", String)
		_includeNamesLang = metaAnnotation.value("includeNamesLang", String)
		
		_includeNamesPrefix =  metaAnnotation.value("includeNamesPrefix", String) ?: ""
		_includeNamesSuffix = metaAnnotation.value("includeNamesSuffix", String) ?: ""
		_includeRules = metaAnnotation.value("includeRules", typeof(AnnotationMirror[])).map[
			createElementMatcher(it)]
		_excludeRules = metaAnnotation.value("excludeRules", typeof(AnnotationMirror[])).map[
			createElementMatcher(it)]
		_ruleSource = metaAnnotation.value("ruleSource", Properties.RuleSource)
		_fromFields = metaAnnotation.value("fromFields", Boolean)
	}
}
