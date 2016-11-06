package de.japkit.rules

import de.japkit.metaannotations.Trigger
import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenAnnotationValue
import de.japkit.model.GenExtensions
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.MessageCollector
import de.japkit.services.ProcessingException
import de.japkit.services.TypeElementNotFoundException
import de.japkit.services.TypesExtensions
import java.util.ArrayList
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement

class AnnotationExtensions {
	extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val transient extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)

	def List<GenAnnotationMirror> overrideAnnotations(Element overrideElement,
		List<GenAnnotationMirror> existingAnnotations) {
		if (overrideElement == null) {
			return new ArrayList(existingAnnotations)
		}

		val result = new ArrayList(existingAnnotations.filter [ am |
			!overrideElement.annotationMirrors.exists[fqn.equals(am.fqn)]
		].toList)

		result.addAll(ExtensionRegistry.get(GenExtensions).copyAnnotations(overrideElement))

		result
	}

	public val SHADOW_AV = "shadow"

	def isShadowAnnotation(AnnotationMirror am) {
		Boolean.TRUE.equals(am?.value(SHADOW_AV, Boolean))
	}

	def setShadowIfAppropriate(GenAnnotationMirror am) {
		if (am.shallSetShadow) {
			am.setValue(SHADOW_AV, new GenAnnotationValue(true))
		}
	}

	def private boolean shallSetShadow(GenAnnotationMirror am) {

		// set the "shadow" annotation value if the annotation triggers code generation for a class
		// and if the annotation type declares a boolean shadow AV
		isTriggerAnnotation(am) &&
			{
				val avMethod = am.getAVMethod(SHADOW_AV, false)

				if (avMethod == null || !avMethod.returnType.
					boolean) {
					throw new ProcessingException(
					'''The annotation value '«SHADOW_AV»' could not be set on annotation «am.annotationType», since it is not declared in the annotation type or is not boolean.''',
						null)
				}

				true
			}

	}

	def isTriggerAnnotation(AnnotationMirror am) {
		try {
			am.hasMetaAnnotation(Trigger.name)
		} catch (TypeElementNotFoundException e) {
			// If the annotation type cannot be found, we assume it is no trigger annotation. 
			// That is: We do not support to generate new trigger annotations (which would be strange anyway.)
			// This error handling is necessary, since some annotations ARE generated, especially annotation templates.
			return false;
		}
	}

	def isTriggerAnnotation(TypeElement te) {
		te.annotationMirror(Trigger.name) != null
	}

	def List<? extends AnnotationMirror> getTriggerAnnotations(TypeElement annotatedClass) {
		annotatedClass.annotationMirrors.filter[isTriggerAnnotation].toList
	}


}
