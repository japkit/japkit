package de.japkit.test.members.common.condition;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import de.japkit.metaannotations.Trigger;

/**
 * The trigger annotation for the example. Refers to the template describing the
 * class to be generated.
 */
@Documented
@Trigger(template = ConditionTemplate.class)
@Target(ElementType.TYPE)
public @interface ConditionTrigger {
	/**
	 * All trigger annotations in japkit must have this annotation value. When
	 * generating a class, the trigger annotation is copied to the generated
	 * class and shadow is set to false to mark it as a copy.
	 * 
	 * @return true means, it is a copy of the original annotation.
	 */
	boolean shadow() default false;

	/**
	 * This annotation value is used as condition to trigger generation of
	 * someField1, someMethod and someInnerClass. Annotation values from the
	 * trigger annotation are provided as variables to be used in expressions,
	 * like "#{shallGenerateMembers}".
	 * 
	 * @return true means, the members shall be generated.
	 */
	boolean shallGenerateMembers() default false;
}