package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenMethod
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier

@Data
class MethodRule extends ExecutableElementRule<GenMethod> {

	
	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
		addAfterCreationRule(ru.createTypeRule(metaAnnotation, template?.returnType, "return")) [m,t | m.setReturnType(t)]
	}

	protected override createMember(Element ruleSrcElement) {
		val method = createMemberAndSetCommonAttributes(ruleSrcElement, [new GenMethod(it)])
		method
	}

	

}
