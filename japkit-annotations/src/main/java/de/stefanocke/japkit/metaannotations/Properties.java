package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * Meta-Annotation to add properties to a generated class. The properties come
 * from some other class, so it is basically a "projection".
 * 
 * @author stefan
 * 
 */
@Retention(RetentionPolicy.CLASS)
@MemberGeneratorAnnotation
public @interface Properties {
	enum RuleSource {
		/**
		 * The source element is the property. Property is a derived element
		 * which refers to the field and to the getter as far as available. When
		 * getting the type, the annotations, the modifiers, ... of the
		 * property, it will delegate these method calls to the field if
		 * available. Otherwise it will delegate to the getter.
		 */
		PROPERTY,

		/**
		 * The source element for the rules is the field representing the
		 * property.
		 */
		FIELD,

		/**
		 * The source element for the rules is the getter representing the
		 * property.
		 */
		GETTER
	}

	/**
	 * By default, this Property annotation is active an will generate
	 * properties. To switch it on or of case by case, a Matcher can be used
	 * here. The element on which the matcher is applied is the annotated class.
	 * 
	 * @return
	 */
	Matcher[] activation() default {};

	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Properties annotation, it must use this prefix
	 * 
	 * @return
	 */
	String _prefix() default "properties";

	/**
	 * The source class where the properties are taken from.
	 * 
	 * @return the source class
	 */
	Class<?> sourceClass() default None.class;

	/**
	 * 
	 * Creates constants for the names of the properties. If we are in an enum,
	 * enum constants will be created.
	 * 
	 * @return
	 */
	boolean createNameConstants() default false;

	/**
	 * Whether to create properties at all. Can be switched of to only create
	 * name constants. See above.
	 * 
	 * @return
	 */
	boolean createProperties() default true;

	/**
	 * 
	 * @return true means, the properties are based on the declared fields of
	 *         the source class. False means, they are based on the declared and
	 *         inherited getters of the source class.
	 */
	boolean fromFields() default false;

	/**
	 * Determines the source elements for rules (annotation mappings, include
	 * rules, exclude rules). By default, this is the Property element. Property
	 * is a derived element which refers to the field and to the getter as far
	 * as available. When getting the type, the annotations, the modifiers, ...
	 * of the property, it will delegate these method calls to the field if
	 * available. Otherwise it will delegate to the getter.
	 * <p>
	 * By switching to FIELD or GETTER you can enforce that they are used
	 * instead. For instance, this makes sense, if you know you have your
	 * annotations to be mapped always on fields.
	 * 
	 * @return
	 */
	RuleSource ruleSource() default RuleSource.PROPERTY;

	/**
	 * Maps annotations from source class properties to target class fields.
	 * 
	 * @return the annotation mappings.
	 */
	AnnotationMapping[] annotationMappings() default {};

	/**
	 * A class to customize the properties. So far, you can override the annotations of the properties.
	 * 
	 * @return
	 */
	Class<?> overrides() default None.class;

	/**
	 * By default, all fields of the "overrides" class are considered. This can
	 * be changed by setting another matcher here. For example, only fields with
	 * some specific annotation could be considered. Or, methods could be
	 * considered that are named like the properties.
	 * 
	 * @return
	 */
	Matcher overridesMatcher() default @Matcher(srcKind = ElementKind.FIELD);


	Modifier[] fieldModifiers() default { Modifier.PRIVATE };


	/**
	 * Names of properties to be included. They must exist in the source class,
	 * otherwise an error is reported.
	 * 
	 * @return the property names
	 */
	String[] includeNames() default {};

	/**
	 * Rules for including properties. If at least one of the matcher matches
	 * the property, than it is included.
	 * 
	 * @return the element matchers
	 */
	Matcher[] includeRules() default { @Matcher }; // By default, include all
													// found properties. (An
													// empty Matcher matches
													// everything...)

	/**
	 * Rules for excluding properties. If at least one of the matcher matches
	 * the property, than it is not included, even if the include rules say so.
	 * 
	 * @return
	 */
	Matcher[] excludeRules() default {};

	/**
	 * If true, properties that already exist in the superclass of the generated
	 * class, are not generated again.
	 * 
	 * @return
	 */
	boolean excludePropertiesFromSuperclass() default true;
	
	

	/**
	 * A Setter annotation here means to generate a setter for the field. The
	 * annotation can be used to further customize the setter, but all values
	 * are optional.
	 * 
	 * @return the setter annotation
	 */
	Setter[] setter() default @Setter;

	/**
	 * A Getter annotation here means to generate a getter for the field. The
	 * annotation can be used to further customize the getter, but all values
	 * are optional.
	 * 
	 * @return the setter annotation
	 */
	Getter[] getter() default @Getter;

	/**
	 * The delegate methods to create. The delegate is the property.
	 * 
	 * @return
	 */
	DelegateMethods[] delegateMethods() default {};

	/**
	 * Templates to apply per property.
	 * 
	 * @return
	 */
	Class<?>[] templates() default {};

	@interface List {
		Properties[] value();
	}
}
