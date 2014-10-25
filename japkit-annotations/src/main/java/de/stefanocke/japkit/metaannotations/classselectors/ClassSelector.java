package de.stefanocke.japkit.metaannotations.classselectors;

import java.lang.annotation.Annotation;
import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

@Target(ElementType.TYPE)
public @interface ClassSelector {
	/**
	 * 
	 * @return the kind of the class selector.
	 */
	ClassSelectorKind kind() default ClassSelectorKind.EXPR;

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
	 * @return for {@link ClassSelectorKind#EXPR} and as fallback for
	 *         TYPE_MIRROR and INNER_CLASS_NAME, if the AV does not exist.
	 */
	String expr() default "";

	String lang() default "";

	/**
	 * 
	 * @return for {@link ClassSelectorKind#INNER_CLASS_NAME} only: the
	 *         enclosing class. Default is the annotated class.
	 */
	Class<?> enclosing() default AnnotatedClass.class;

	/**
	 * If set, it will be validated whether the resolved class has this trigger
	 * annotation. Moreover, it will be checked whether the class is the
	 * original annotated class or the generated class. If it is the original
	 * annotated class, the FQN of the generated class will be determined
	 * according to the trigger annotation and its Clazz annotation.
	 * The resulting type will then be the generated class.
	 * 
	 * @return
	 */
	Class<? extends Annotation>[] requiredTriggerAnnotation() default {};
}
