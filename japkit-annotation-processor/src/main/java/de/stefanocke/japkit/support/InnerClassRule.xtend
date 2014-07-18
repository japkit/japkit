package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.processor.ClassGeneratorSupport
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement

class InnerClassRule extends MemberRuleSupport<TypeElement, GenTypeElement> {
	val extension ClassGeneratorSupport = ExtensionRegistry.get(ClassGeneratorSupport)

	new(AnnotationMirror metaAnnotation, TypeElement template) {
		super(metaAnnotation, template)
	}

	override protected GenTypeElement createMember(Element ruleSrcElement) {
			
		//The name expression for an inner class is not based on the annotated class but
		//on the current rule source element. Thus, we apply the same logic here as for other member rules
		//and then pass the name to the class generator.
		val name = nameRule.apply(ruleSrcElement)
			
		
		//TODO: Avoid those params, if possible
		generateClass(currentAnnotatedClass, currentGeneratedClass, currentAnnotation, metaAnnotation, template, name, null)
	}
	
	override protected createMember(Element ruleSrcElement, String name) {
		throw new UnsupportedOperationException("Not used here.")
	}

}
