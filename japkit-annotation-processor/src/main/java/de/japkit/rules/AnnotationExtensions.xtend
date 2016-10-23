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

	/**
	 * Maps annotations from a source element.
	 * 
	 * @param srcElement the source element
	 * @param annotatedClass the annotated class
	 * @param annotation the annotation that triggered the annotation processor
	 * @param the meta annotation that contains a value "annotations" which is an array of @_Annotation annotations that specify how to map the annotations.
	 * 
	 * @return the list of generated annotations to be put on the target element. 
	 */
	def List<GenAnnotationMirror> mapAnnotations(Iterable<? extends AnnotationMappingRule> mappings) {
		mapAnnotations(mappings, newArrayList)
	}

	def List<GenAnnotationMirror> mapAnnotations(Iterable<? extends AnnotationMappingRule> mappings,
		List<GenAnnotationMirror> existingAnnotations) {

		try {

			val annotations = existingAnnotations
			mappings.forEach[mapOrCopyAnnotations(annotations)]
			annotations

		} catch (TypeElementNotFoundException tenfe) {
			throw tenfe;
		} catch (RuntimeException re) {
			messageCollector.reportRuleError("Error during annotation mapping." + re)
			emptyList
		}

	}

	def List<GenAnnotationMirror> overrideAnnotations(Element overrideElement,
		List<GenAnnotationMirror> existingAnnotations) {
		if (overrideElement == null) {
			return new ArrayList(existingAnnotations)
		}

		val result = new ArrayList(existingAnnotations.filter [am |
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

				if (avMethod == null ||
					!avMethod.returnType.
						boolean) {
							throw new ProcessingException(
					'''The annotation value '«SHADOW_AV»' could not be set on annotation «am.annotationType», since it is not declared in the annotation type or is not boolean.''',
								null)
						}

						true
					}

			}

			def isTriggerAnnotation(AnnotationMirror am) {
				am.hasMetaAnnotation(Trigger.name)
			}

			def isTriggerAnnotation(TypeElement te) {
				te.annotationMirror(Trigger.name) != null
			}

			/**
			 * Gets a list of element matchers from an annotation.
			 */
			def elementMatchers(AnnotationMirror annotation, CharSequence avName) {
				val av = (annotation.value(avName, typeof(AnnotationMirror[])))
				if(av != null) av.map[createElementMatcher(it)] else emptyList
			}

			def List<AnnotationMappingRule> annotationMappings(AnnotationMirror annotation, CharSequence avName) {
				val result = newArrayList();
				// To refer to annotation rules from annotation value rules, the annotation rules are collected by id here and 
				// this map is passed through to the annotation value rules, so they can lazily get the annotation mappings
				val annotationMappingsById = newHashMap();
				annotation.value(avName, typeof(AnnotationMirror[]))?.forEach [
					val amr = createAnnotationMappingRule(it, annotationMappingsById)
					if (amr.id.nullOrEmpty) {
						//Only add "top-level" annotation mappings
						result.add(amr)
					} else {
						//Mappings with id are used from within annotation value mappings. Provide lookup for them via a map
						annotationMappingsById.put(amr.id, amr);
					}
				]
				result
			}

		}
		