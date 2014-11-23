package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.GenElement
import de.stefanocke.japkit.model.GenTypeElement
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function1

@Data
class TemplateCallRule extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>> {
	val ()=>boolean activationRule 
	val ((Object)=>Iterable<? extends GenElement>)=>List<Iterable<? extends GenElement>> scopeRule 
	val TemplateRule templateRule 
	
	new(AnnotationMirror templateCallAnnotation) {
		super(templateCallAnnotation, null)
		activationRule = createActivationRule(templateCallAnnotation, null)
		scopeRule = createScopeRule(templateCallAnnotation, null, null)
		templateRule = createTemplateRule(templateCallAnnotation.value("value", TypeElement));
	}

	override apply(GenTypeElement genClass) {
		inRule[
			if (!activationRule.apply) {
				emptyList
			} else {
				scopeRule.apply[
					templateRule.apply(genClass)		
				].flatten.toList
			}	
		]
	}

}
