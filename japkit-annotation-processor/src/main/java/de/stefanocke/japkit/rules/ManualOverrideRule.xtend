package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ELSupport
import de.stefanocke.japkit.model.GenAnnotationMirror
import de.stefanocke.japkit.model.GenElement
import de.stefanocke.japkit.services.ElementsExtensions
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.MessageCollector
import de.stefanocke.japkit.services.TypeResolver
import de.stefanocke.japkit.services.TypesRegistry
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

@Data
class ManualOverrideRule {
	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension TypeResolver = ExtensionRegistry.get(TypeResolver)
	val transient extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val transient extension ELSupport =  ExtensionRegistry.get(ELSupport)
	val protected transient extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)

	//The class selector for manual overrides
	TypeMirror manualOverrides	
	(Element)=>boolean manualOverridesMatcher
	
	new(AnnotationMirror metaAnnotation){
		manualOverrides = metaAnnotation?.value("manualOverrides", TypeMirror)
		manualOverridesMatcher = metaAnnotation?.value("manualOverridesMatcher", AnnotationMirror)?.createElementMatcher
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