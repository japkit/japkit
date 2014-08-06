package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenTypeElement
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement

interface MemberGenerator {
	/**
	 * @param membersClass the class that carries the members meta-annotation
	 * @param annotatedClass the annotated class with the trigger annotation
	 * @param generatedClass the generated class or interface to which to contribute members to 
	 * @param triggerAnnotation the trigger annotation
	 * @param metaAnnotationToBeProcessed the meta annotation to be processed
	 * @param genClassMetaAnnotation the GenClass meta annotation which triggered the creation of the generatedClass.
	 * @param env Callback interface RFU
	 */
	def void createMembers(
		TypeElement membersClass,
		TypeElement annotatedClass,
			GenTypeElement generatedClass, AnnotationMirror triggerAnnotation,
			AnnotationMirror metaAnnotationToBeProcessed)
	
	/**
	 * 
	 * @return the fqn of the supported meta-annotation
	 */
	def String getSupportedMetaAnnotation()
}