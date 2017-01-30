package de.japkit.rules

import de.japkit.model.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data

@Data
class InnerClassRule extends MemberRuleSupport<TypeElement, GenTypeElement> {
	
	ClassRule classRule

	new(AnnotationMirror metaAnnotation, TypeElement template) {
		super(metaAnnotation, template)
		classRule = new ClassRule(metaAnnotation, template, false)
	}

	override protected createMember(String name) {
		//The name expression for an inner class is not based on the annotated class but
		//on the current rule source element. Thus, we apply the same logic here as for other member rules
		//and then pass the name to the class generator.
		classRule.generateClass(name, null).head 
	}
	
	override protected applyRulesAfterCreation(GenTypeElement member) {
		//deactivate rules for comment, annotations and modifiers since this is done by the ClassRule
	}

}
