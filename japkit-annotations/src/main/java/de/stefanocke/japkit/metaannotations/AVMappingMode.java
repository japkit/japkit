package de.stefanocke.japkit.metaannotations;

public enum AVMappingMode {
	/**
	 * If the annotation value already exists (due to previous mapping rule or due to
	 * "copy"), it is an error.
	 */
	ERROR_IF_EXISTS,

	/**
	 * If the annotation value already exists, it is removed and replaced by the new one.
	 */
	REPLACE,

	/**
	 * If the annotation value already exists, it is removed and not generated again.
	 * This can be used for blacklisting. (For example, copy all annotations at
	 * first, and then remove some annotation values under some conditions). 
	 */
	REMOVE,

	/**
	 * If the annotation value already exists, the mapping rule is ignored and the
	 * annotation stays at it is.
	 */
	IGNORE,

	/**
	 * If the annotation value already exists and it is an array, the generated new values are added to the existing ones.
	 */
	JOIN_LIST,
	
	/** 
	 * This mode is only supported if the annotation value is an annotation. If so, the existing annotation is re-used and the value mappings will
	 * be applied to it according to their mapping modes. 
	 */
	MERGE
}
