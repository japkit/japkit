package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenConstructor
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement

class ConstructorRule extends ExecutableElementRule<GenConstructor> {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}
	
	override protected createMember(Element ruleSrcElement, String name) {
		new GenConstructor
	}
	
	override protected createNameRule() {
		RuleUtils.NO_NAME
	}

	

}
