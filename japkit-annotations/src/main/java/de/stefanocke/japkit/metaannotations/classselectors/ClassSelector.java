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
