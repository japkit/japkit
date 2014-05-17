package de.stefanocke.japkit.metaannotations.classselectors;

public enum ClassSelectorKind{

	/**The class is given by an annotation value of type Class.*/
	TYPE_MIRROR,
	
	/**The class is an inner class of the annotated class. The annotation value is the name of the inner class*/
	INNER_CLASS_NAME,
	
	/**No class selected.
	 * <p>
	 * If used for a type argument, a type parameter of the generated class is used. The type parameter is searched in the generated class by the name of the type variable. If it is found, it is used.
	 * If not, a new type parameter is created and used.
	 * <p>
	 * In most other cases this will yield void. 
	 */
	NONE,
	
	/**To refer to the annotated class*/
	ANNOTATED_CLASS,
	
	/**To refer to the generated class*/
	GENERATED_CLASS,
	
	/**
	 * To refer to the type of the current rule source element.
	 */
	SRC_ELEMENT_TYPE,
	
	/**
	 * To refer to the type of the current rule source element. In case of a collection, the element type is used. In case of a map, the value type is used.
	 */
	SRC_ELEMENT_SINGLE_VALUE_TYPE,
	
	/**
	 * An EL expression is used to determine the type.
	 */
	EXPR
}