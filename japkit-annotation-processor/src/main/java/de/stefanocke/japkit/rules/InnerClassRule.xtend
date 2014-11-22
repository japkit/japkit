package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

@Data
class InnerClassRule extends MemberRuleSupport<TypeElement, GenTypeElement> {
	
	ClassRule classRule

	new(AnnotationMirror metaAnnotation, TypeElement template) {
		super(metaAnnotation, template)
		_classRule = new ClassRule(metaAnnotation, template, false)
	}

	override protected GenTypeElement createMember() {
			
		//The name expression for an inner class is not based on the annotated class but
		//on the current rule source element. Thus, we apply the same logic here as for other member rules
		//and then pass the name to the class generator.
		val name = nameRule.apply
			
		
		
		val clazz = classRule.generateClass(name, null).head 
			
		clazz.comment = commentRule.apply
		
		clazz
	}
	
	override protected createMember(String name) {
		throw new UnsupportedOperationException("Not used here.")
	}

}
