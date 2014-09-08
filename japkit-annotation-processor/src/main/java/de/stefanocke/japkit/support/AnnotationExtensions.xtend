package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenAnnotationValue
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import java.util.ArrayList
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.metaannotations.Clazz
import javax.lang.model.element.TypeElement

class AnnotationExtensions {
	extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val extension RuleFactory =  ExtensionRegistry.get(RuleFactory)
	val extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val extension ELSupport = ExtensionRegistry.get(ELSupport)

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
	def List<GenAnnotationMirror> mapAnnotations(Iterable<? extends AnnotationMappingRule> mappings, List<GenAnnotationMirror> existingAnnotations) {
		
		try {

			val mappingsWithId = mappings.filter[!id.nullOrEmpty].toMap[id]

			val annotations = existingAnnotations
			mappings.filter[id.nullOrEmpty].forEach[mapOrCopyAnnotations(annotations, mappingsWithId)]
			annotations

		} catch (TypeElementNotFoundException tenfe) {
			throw tenfe;
		} catch (RuntimeException re) {
			messageCollector.reportRuleError("Error during annotation mapping." + re)
			emptyList
		}

	}
	

	
	def List<GenAnnotationMirror> overrideAnnotations(Element overrideElement, List<GenAnnotationMirror> existingAnnotations) {
		if(overrideElement==null){
			return new ArrayList(existingAnnotations)
		}
		
		val result = new ArrayList(existingAnnotations.filter[am | !overrideElement.annotationMirrors.exists[fqn.equals(am.fqn)]].toList)
		
		result.addAll(ExtensionRegistry.get(GenExtensions).copyAnnotations(overrideElement))
		
		result
	}

	public val SHADOW_AV = "shadow"

	def isShadowAnnotation(AnnotationMirror am) {
		Boolean.TRUE.equals(am?.value(SHADOW_AV)?.value)
	}

	def setShadowIfAppropriate(GenAnnotationMirror am) {
		if (am.shallSetShadow) {
			am.setValue(SHADOW_AV, new GenAnnotationValue(true))
		}
	}

	def private boolean shallSetShadow(GenAnnotationMirror am) {

		//set the "shadow" annotation value if the annotation triggers code generation for a class
		// and if the annotation type declares a boolean shadow AV
		isTriggerAnnotation(am) && {
			val avMethod = am.getAVMethod(SHADOW_AV, false)

			if (avMethod == null || !avMethod.returnType.boolean) {
				throw new ProcessingException(
					'''The annotation value '«SHADOW_AV»' could not be set on annotation «am.annotationType», since it is not declared in the annotation type or is not boolean.''',
					null)
			}

			true
		}

	}
	
	//TODO: Verallgemeinern. Ggf. @Trigger
	def isTriggerAnnotation(GenAnnotationMirror am) {
		am.hasMetaAnnotation(Clazz.name)
	}
	
	def isTriggerAnnotation(TypeElement te) {
		te.annotationMirror(Clazz.name) != null
	}
	
	/**
	 * Gets a list of element matchers from an annotation.
	 */
	 def elementMatchers(AnnotationMirror annotation, CharSequence avName, AnnotationMirror metaAnnotation){
	 	 val av =(annotation.valueOrMetaValue(avName, typeof(AnnotationMirror[]), metaAnnotation))
	 	 if(av!=null) av.map[createElementMatcher(it)] else emptyList
	 }
	 
	 def annotationMappings(AnnotationMirror annotation, CharSequence avName, AnnotationMirror metaAnnotation){
	 	 annotation.valueOrMetaValue(avName, typeof(AnnotationMirror[]), metaAnnotation)?.map[createAnnotationMappingRule(it)] ?: emptyList
	 }
	 
	 def annotationMappings(AnnotationMirror annotation, CharSequence avName){
	 	 annotation.value(avName, typeof(AnnotationMirror[]))?.map[createAnnotationMappingRule(it)] ?: emptyList
	 }
	 
	
}
