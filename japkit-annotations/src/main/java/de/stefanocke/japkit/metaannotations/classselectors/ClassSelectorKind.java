package de.stefanocke.japkit.metaannotations.classselectors;

public enum ClassSelectorKind{

	/**The class is given by an annotation value of type Class.*/
	TYPE_MIRROR,
	
	/**The class is an inner class of the given enclosing class. The result of the expression is the name of the inner class. 
	 * If no expression is set, the name of the class is used, where this annotation is located at.*/
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
	 * To refer to the type of the current source element or (if the source is a type itself) the source.
	 */
	SRC_TYPE,
	
	/**
	 * To refer to the type of the current rule source element. In case of a collection, the element type is used. In case of a map, the value type is used.
	 */
	SRC_SINGLE_VALUE_TYPE,
	
	/**
	 * An EL expression is used to determine the type.
	 */
	EXPR
}