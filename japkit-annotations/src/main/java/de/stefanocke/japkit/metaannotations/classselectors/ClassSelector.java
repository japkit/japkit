package de.stefanocke.japkit.metaannotations.classselectors;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

@Target(ElementType.TYPE)
public @interface ClassSelector {
	/**
	 * 
	 * @return the kind of the class selector.
	 */
	ClassSelectorKind kind() default ClassSelectorKind.TYPE_MIRROR;

	/**
	 * 
	 * @return the name of the annotation value of the trigger annotation.
	 *         <p>
	 *         In case of ClassSelectorKind.TYPE_MIRROR that annotation value
	 *         must be of type Class<?>.
	 *         <p>
	 *         In case of ClassSelectorKind.INNER_CLASS_NAME it must be of type
	 *         String.
	 *         <p>
	 *         In case of ClassSelectorKind.SPECIAL it depends on the selector.
	 *         Usually, it is ignored at all.
	 *         <p>
	 *         If empty, the annotation value name defaults to the simple class
	 *         name of the class annotated with ClassSelector with first
	 *         character converted to lower case.
	 */
	String avName() default "";
	
	/**
	 * 
	 * @return for {@link ClassSelectorKind#EXPR} and as fallback for TYPE_MIRROR and INNER_CLASS_NAME, if the AV does not exist.
	 */
	String expr() default "";
	
	String lang() default "";
	
	/**
	 * 
	 * @return for {@link ClassSelectorKind#INNER_CLASS_NAME} only: the enclosing class. Default is the annotated class.
	 */
	Class<?> enclosing() default AnnotatedClass.class;
}
