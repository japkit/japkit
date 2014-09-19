package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror

@Data
class ManualOverrideRule {
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension TypeResolver = ExtensionRegistry.get(TypeResolver)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val extension ELSupport =  ExtensionRegistry.get(ELSupport)
	val protected extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)

	//The class selector for manual overrides
	TypeMirror manualOverrides	
	(Element)=>boolean manualOverridesMatcher
	
	new(AnnotationMirror metaAnnotation){
		_manualOverrides = metaAnnotation?.value("manualOverrides", TypeMirror)
		_manualOverridesMatcher = metaAnnotation?.value("manualOverridesMatcher", AnnotationMirror)?.createElementMatcher
	}
	
	def apply(Iterable<? extends GenElement> elementsToOverride){
		val overridesSource = manualOverrides?.resolveType?.asTypeElement
		if(overridesSource==null) return;
		
		val overrideElementsByName = (overridesSource?.enclosedElements?.filter[manualOverridesMatcher.apply(it)] ?: emptyList).toMap[simpleName.toString]
		
		val elementsToOverrideNames = elementsToOverride.map[simpleName.toString].toSet
		
		//Validate that an according property exists for each override element 
		overrideElementsByName.forEach [ oeName, oe |
			if (!elementsToOverrideNames.contains(oeName)) {
				scope(oe)[
					//TODO: Das ist kein Error in einer Rule, sondern eben nur in einer annotierten Klasse bzw Hilfsklasse.
					reportRuleError('''No generated element exists with name «oeName». Generated elements are: «elementsToOverrideNames»''')	
					null		
				]
			}
		]
		
		elementsToOverride.forEach[
			val overrideElement = overrideElementsByName.get(it.simpleName.toString)
			if(overrideElement!=null){
				annotationMirrors = overrideAnnotations(overrideElement, annotationMirrors as List<GenAnnotationMirror>)			
			}
		]
		
	}
		
}