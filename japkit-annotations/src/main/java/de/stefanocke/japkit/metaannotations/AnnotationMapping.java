package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Annotation;

@MemberGeneratorAnnotation
public @interface AnnotationMapping {

	/**
	 * An identifier to refer to this annotation mapping within annotation value
	 * mappings. If this value is set, the annotation mapping is only applied
	 * within those annotation value mappings that refer to it, but not as a top
	 * level mapping.
	 * <p>
	 * The reason for this mechanism is that annotations cannot be contain
	 * themselves recursively.
	 * 
	 * @return the id
	 */
	String id() default "";

	/**
	 * By default, this annotation mapping is active an will copy or map the annotations.
	 * To switch it on or of case by case, a Matcher can be used here. 
	 * <p>
	 * In case of multiple matchers, at least one must match to activate the
	 * rule.
	 * 
	 * @return the matcher
	 */
	Matcher[] activation() default {};

	/**
	 * 
	 * @return the annotations to copy from source to target element.
	 */
	Class<? extends Annotation>[] copyAnnotations() default {};

	/**
	 * 
	 * @return annotations contained in those packages will be copied from
	 *         source to target element. The package names must either end with
	 *         .* or with .**. In case of .* only the package itself is
	 *         considered. In case of .**, the sub packages are considered as
	 *         well. For including all packages, use *.
	 */
	String[] copyAnnotationsFromPackages() default {};

	/**
	 * When copying annotations that trigger code generation, this will
	 * introduce infinite loops. Thus, when a trigger annotation is copied, an
	 * annotation value named "shadow" will be searched and set to true. The
	 * annotation processor will skip such annotations in the next round. It is
	 * an error if a trigger annotation to be copied does not declare an
	 * annotation value with the name "shadow".
	 * 
	 * @return true means to set the annotation value "shadow" will be set to
	 *         true.
	 */
	boolean setShadowOnTriggerAnnotations() default true;

	/**
	 * 
	 * @return the annotation to be created on the target element.
	 */
	Class<? extends Annotation> targetAnnotation() default DefaultAnnotation.class;

	/**
	 * 
	 * @return mappings for the annotation values
	 */
	AVMapping[] valueMappings() default {};

	AnnotationMappingMode mode() default AnnotationMappingMode.ERROR_IF_EXISTS;

	/**
	 * For mode AnnotationMappingMode.AS_ANNOTATION_VALUE: The annotation in
	 * where to add / set the target annotation as annotation value. If it does
	 * not exist (yet), it is created.
	 */
	Class<? extends Annotation> asAvAnnotation() default DefaultAnnotation.class;

	/**
	 * For mode AnnotationMappingMode.AS_ANNOTATION_VALUE: The name of the
	 * annotation value where to add / set the target annotation.
	 */
	String asAvAnnotationValueName() default "value";

	/**
	 * For mode AnnotationMappingMode.AS_ANNOTATION_VALUE: the annotation value
	 * mapping mode.
	 * 
	 */
	AVMappingMode asAvMode() default AVMappingMode.ERROR_IF_EXISTS;
	
	@interface List {
		AnnotationMapping[] value();
	}
}
