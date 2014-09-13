package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenTypeElement
import java.util.List
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtext.xbase.lib.Functions.Function1
import javax.lang.model.element.TypeElement

@Data
class TemplateCallRule extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>> {
	val ()=>boolean activationRule 
	val ((Object)=>Iterable<? extends GenElement>)=>List<Iterable<? extends GenElement>> scopeRule 
	val TemplateRule templateRule 
	
	new(AnnotationMirror templateCallAnnotation) {
		super(templateCallAnnotation, null)
		_activationRule = createActivationRule(templateCallAnnotation, null)
		_scopeRule = createScopeRule(templateCallAnnotation, null, null)
		_templateRule = createTemplateRule(templateCallAnnotation.value("value", TypeElement));
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
