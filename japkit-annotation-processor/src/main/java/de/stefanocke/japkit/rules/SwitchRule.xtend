package de.stefanocke.japkit.rules

import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.metaannotations.Case

@Data
class SwitchRule<T> extends AbstractFunctionRule<T>{
	
	List<CaseRule<T>> caseRules
	
	new(AnnotationMirror switchAnnotation, Element metaElement){
		super(switchAnnotation, metaElement, null)
		
		//The case rules are either in the Switch annotation or the Switch annotation is a class and its members
		//are annotated with Case annotations. 
		val caseRulesFromAnnotation = switchAnnotation.value("value", typeof(AnnotationMirror[])).map[ caseAm |
			new CaseRule<T>(caseAm, null, type)
		]
		
		caseRules = if(caseRulesFromAnnotation.nullOrEmpty && metaElement instanceof TypeElement) {
			(metaElement as TypeElement).enclosedElements
				.map[ it -> it.annotationMirror(Case)]
				.filter[value != null].map[ new  CaseRule<T>(value, key, type)]
				.toList
		} else caseRulesFromAnnotation
	}
	
	override protected evalInternal() {
		CaseRule.applyFirstMatching(caseRules)
	}
		

}