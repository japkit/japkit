package de.stefanocke.japkit.metaannotations;

/**
 * 
 * @author stefan
 * 
 */
public enum AnnotationMappingMode {
	/**
	 * If the same annotation exists (due to previous mapping rule or due to
	 * "copy"), it is an error.
	 */
	ERROR_IF_EXISTS,

	/**
	 * If the same annotation exists, it is re-used and the value mappings will
	 * be applied according to their mapping modes. (See
	 * {@link AVMappingMode})
	 */
	MERGE,

	/**
	 * If the same annotation exists, it is removed and replaced by the new one.
	 */
	REPLACE,

	/**
	 * If the same annotation exists, it is removed and not generated again.
	 * This can be used for blacklisting. (For example, copy all annotations at
	 * first, and then remove some under some conditions).
	 * <p>
	 * Annotation value mappings are ignored in this mode.
	 */
	REMOVE,

	/**
	 * If the same annotation exists, the maaping rule is ignored and the
	 * annotation stays at it is.
	 */
	IGNORE,

	/**
	 * The annotation is used as annotation value within another annotation.
	 * (Note: For this, it would be more consistent to allow AnnotationMappinngs
	 * as values within AVMapping. However, this is not possible,
	 * since the JLS forbids such recursive use of annotations)
	 */
	AS_ANNOTATION_VALUE
}
