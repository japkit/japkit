package de.japkit.rules

import de.japkit.metaannotations.Case
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.element.ElementKind
import de.japkit.metaannotations.DefaultCase
import javax.lang.model.type.TypeMirror

@Data
class SwitchRule extends AbstractFunctionRule<Object> implements ICodeFragmentRule{
	
	List<CaseRule<Object>> caseRules
	ScopeRule<Object> scopeRule
	
	new(AnnotationMirror switchAnnotation, Element metaElement){
		super(switchAnnotation, metaElement, null)
		
		scopeRule = createScopeRule(switchAnnotation, metaElement, null)
		
		//The case rules are either in the Switch annotation or the Switch annotation is a class and its members
		//are annotated with Case annotations. 
		val caseRulesFromAnnotation = switchAnnotation.value("value", typeof(AnnotationMirror[])).map[ caseAm |
			new CaseRule<Object>(caseAm, null, type, false)
		]
		
		caseRules = if(caseRulesFromAnnotation.nullOrEmpty && metaElement instanceof TypeElement) {
			(metaElement as TypeElement).enclosedElementsOrdered
				.filter[ it.kind != ElementKind.CONSTRUCTOR ] //don't create Case-Rule for default constructor
				.map[ new CaseRule<Object>(it.annotationMirror(Case) ?: it.annotationMirror(DefaultCase), it, type, it.annotationMirror(DefaultCase) !== null)]
				.toList
		} else caseRulesFromAnnotation
	}
	
	override List<Pair<Class<?>, String>> createParams(Element element) {
		//If the Switch is a class, support Type Parameters to be passed to type functions in the Cases
		if(metaElement instanceof TypeElement) {
			val te = (metaElement as TypeElement)
			if(te.typeParameters.empty) {
				return null;
			}
			te.typeParameters.map[
				TypeMirror as Class<?> -> '''«te.qualifiedName».«simpleName»'''
			]
		} else {
			super.createParams(element);
		}
		
	}
	
	override protected evalInternal() {
		scopeRule.apply [
			CaseRule.findFirstMatching(caseRules)?.apply		
		].head
	}
	
	
	override code() {
		scopeRule.apply [
			CaseRule.findFirstMatching(caseRules)?.code	
		].head as CharSequence
	}
	
	override surround(CharSequence surrounded) {
		scopeRule.apply [
			//Apply first matching rule or leave the surrounded code unchanged if no rule applies
			CaseRule.findFirstMatching(caseRules)?.surround(surrounded) ?: surrounded
		].head as CharSequence
		
	}
		

}