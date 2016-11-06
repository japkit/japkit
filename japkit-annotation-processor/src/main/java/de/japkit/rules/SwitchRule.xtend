package de.japkit.rules

import de.japkit.metaannotations.Case
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.ElementKind

@Data
class SwitchRule<T> extends AbstractFunctionRule<T> implements ICodeFragmentRule{
	
	List<CaseRule<T>> caseRules
	
	new(AnnotationMirror switchAnnotation, Element metaElement){
		super(switchAnnotation, metaElement, null)
		
		//The case rules are either in the Switch annotation or the Switch annotation is a class and its members
		//are annotated with Case annotations. 
		val caseRulesFromAnnotation = switchAnnotation.value("value", typeof(AnnotationMirror[])).map[ caseAm |
			new CaseRule<T>(caseAm, null, type)
		]
		
		caseRules = if(caseRulesFromAnnotation.nullOrEmpty && metaElement instanceof TypeElement) {
			(metaElement as TypeElement).enclosedElementsOrdered
				.filter[ it.kind != ElementKind.CONSTRUCTOR ] //don't create Case-Rule for default constructor
				.map[ new CaseRule<T>(it.annotationMirror(Case), it, type)]
				.toList
		} else caseRulesFromAnnotation
	}
	
	override protected evalInternal() {
		CaseRule.findFirstMatching(caseRules)?.apply
	}
	
	
	override code() {
		CaseRule.findFirstMatching(caseRules)?.code
	}
	
	override surround(CharSequence surrounded) {
		//Apply first matching rule or leave the surrounded code unchanged if no rule applies
		CaseRule.findFirstMatching(caseRules)?.surround(surrounded) ?: surrounded
	}
		

}