package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.processor.ClassGeneratorSupport
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import de.stefanocke.japkit.gen.GenElement

class InnerClassRule extends MemberRuleSupport<TypeElement> {
	val extension ClassGeneratorSupport = ExtensionRegistry.get(ClassGeneratorSupport)

	new(AnnotationMirror metaAnnotation, TypeElement template) {
		super(metaAnnotation, template)
	}

	override protected GenElement createMember(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
			
		//The name expression for an inner class is not based on the annotated class but
		//on the current rule source element. Thus, we apply the same logic here as for other member rules
		//and then pass the name to the class generator.
		val name = {
			val n = nameRule.apply
			if(n.nullOrEmpty) template?.simpleName.toString else n
		}
		generateClass(annotatedClass, generatedClass, triggerAnnotation, metaAnnotation, template, name, null)
	}

}
