package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * Meta annotation. When put on an annotation, this annotation will generate a
 * new Java class.
 * 
 * @author stefan
 * 
 */
@Retention(RetentionPolicy.CLASS)
@Target(ElementType.ANNOTATION_TYPE)
public @interface GenerateClass {
	
	/**
	 * 
	 * @return the kind of type element to generate. Allowed values: CLASS, INTERFACE, ENUM
	 */
	ElementKind kind() default ElementKind.CLASS;
	
	/**
	 * 
	 * @return the superclass for the generated class. By default it is Object.
	 */
	Class<?> superclass() default Object.class;

	/**
	 * 
	 * @return the type arguments for the superclass
	 */
	Class<?>[] superclassTypeArgs() default {};

	/**
	 * 
	 * @return the interface implemented by the generated class. By default, no
	 *         interface is implemented.
	 */
	Class<?> interface1() default None.class;

	/**
	 * 
	 * @return the type arguments for the interface
	 */
	Class<?>[] interface1TypeArgs() default {};

	/**
	 * 
	 * @return a second interface implemented by the generated class. By
	 *         default, no interface is implemented.
	 */
	Class<?> interface2() default None.class;

	/**
	 * 
	 * @return the type arguments for the second interface
	 */
	Class<?>[] interface2TypeArgs() default {};
	
	/**
	 * If set to true, it will be checked for each relates type, if it has an annotation with a GenerateClass meta annotation.
	 * Where this is the case, the original type will be transformed to the class that will be generates by that a GenerateClass meta annotation.
	 * <p>
	 * By referring to annotated classes instead of generated classes, some issues with not yet existing types can be avoided.
	 * It is strongly suggested to use this approach. (f.e. javac's annotation processing implementation gives the String "<error>" if a non-existing type is used 
	 * as annotation value. This is simply not enough information to properly resolve the type dependency during code generation, especially
	 * in case of cyclic dependencies between generated classes.)
	 * 
	 * @return
	 */
	boolean transformRelatesTypesAccordingToGenClassAnnotation() default false;

	/**
	 * 
	 * @return the modifiers for the generated class
	 */
	Modifier[] modifier() default {};

	String classSuffixToRemove() default "";

	String classSuffixToAppend() default "Gen";

	String classPrefixToRemove() default "";

	String classPrefixToPrepend() default "";

	String classRegEx() default "";

	String classRegExReplace() default "";

	String packageRegEx() default "";

	String packageRegExReplace() default "";
	
	
	/**
	 * If true, a shadow annotation is created by copying the trigger annotation to the generated 
	 * class and setting its "shadow" annotation value to true.
	 * @return
	 */
	boolean createShadowAnnotation() default true;

	/**
	 * How to map annotations of the annotated class to the target class.
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	AnnotationMapping[] annotationMappings() default {};
	
	/**
	 * 
	 * @return the members to be generated for this class. By default, the trigger annotation itself is searched for member annotations.
	 */
	Members[] members() default @Members;

	/**
	 * If true, a custom behavior delegation mechanism is generated. Woohaa...
	 * 
	 * @return
	 */
	boolean customBehavior() default false;

	Class<?> behaviorClass() default BehaviorInnerClass.class;

	/**
	 * 
	 * @return the name of the user written Behavior class, when it is an inner
	 *         class of the annotated class (behaviorClass ==
	 *         BehaviorInnerClass.class)
	 */
	String behaviorInnerClassName() default "Behavior";

	/**
	 * 
	 * @return the name of the base class for the behavior class. It is always
	 *         an inner class of the generated class.
	 */
	String behaviorAbstractClass() default "AbstractBehavior";

	/**
	 * The interface that is provided to the behavior class to access all
	 * methods (espec. including private ones) of the generated class.
	 * 
	 * @return the name of the interface. If it is not an inner class of the
	 *         generated class, than this value is the suffix to append to the
	 *         name of the generated class to get the name of the interface.
	 */
	String behaviorInternalInterface() default "Internal";

	/**
	 * @return true means, the internacl interface is generated as inner class
	 *         of generated class. false means, it is generated as top level
	 *         class. Note: Compilation errors may appear in eclipse, when that is set to true.
	 */
	boolean behaviorInternalInterfaceIsInnerClass() default false;
	
	/**
	 * 
	 * @return the name of the implementation class for the internal interface. This is always an inner class of the generated class.
	 */
	String behaviorInternalInterfaceImpl() default "InternalImpl";
	
	/**
	 * If the user declares a method in the behavior class that already exists in the generated class, than the generated method is renamed.
	 * This allows the used declared method to call the generated method and so kind of "wrapping" it.
	 * <p>
	 * This idea was taken from Eclipse Modeling Framework.
	 * 
	 * @return the prefix to use when renaming a generated method.
	 */
	String behaviorGenMethodRenamePrefix() default "gen";
	
	/**
	 * EL Variables in the scope of the generated class. 
	 * @return
	 */
	Var[] vars() default {};

}
