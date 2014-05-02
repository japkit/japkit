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

	/**
	 * 
	 * @return whether to generate getters at all
	 */
	boolean generateGetters() default true;

	/**
	 * Whether getters shall return unmodifiable collections and maps
	 * 
	 * @return
	 */
	boolean returnUnmodifiableCollections() default false;

	/**
	 * Whether getters shall return defensive copies of the properties.
	 * <p>
	 * If the property is a collection, and gettersReturnUnmodifiableCollections
	 * is set, this option will be ignored.
	 * <p>
	 * If the type of the property is known to be immutable, no defensive copy
	 * is created. Types from the following categories are considered immutable:
	 * TypeCategory.PRIMITIVE, TypeCatergory.STRING, TypeCategory.MATH,
	 * TypeCategory.ENUM
	 * <p>
	 * There are built in copy mechanisms for the following type categories
	 * TypeCategory.TEMPORAL, TypeCategory.COLLECTION, TypeCategory.ARRAY
	 * <p>
	 * Note: For collections and arrays, only shallow copies are created. 'Deep
	 * cloning' is not supported here.
	 * 
	 * @return
	 */
	boolean returnDefensiveCopies() default false;

	/**
	 * Whether setters shall create defensive copies before assigning the value
	 * to the field.
	 * <p>
	 * If the type of the property is known to be immutable, no defensive copy
	 * is created. Types from the following categories are considered immutable:
	 * TypeCategory.PRIMITIVE, TypeCatergory.STRING, TypeCategory.MATH,
	 * TypeCategory.ENUM
	 * <p>
	 * There are built in copy mechanisms for the following type categories
	 * TypeCategory.TEMPORAL, TypeCategory.COLLECTION, TypeCategory.ARRAY
	 * <p>
	 * Note: For collections and arrays, only shallow copies are created. Deep
	 * 'cloning' is not supported here.
	 * 
	 * 
	 * @return
	 */
	boolean assignDefensiveCopies() default false;

	Matcher[] returnDefensiveCopiesAlsoFor() default {};

	Matcher[] assignDefensiveCopiesAlsoFor() default {};

	@SuppressWarnings("rawtypes")
	Class<? extends java.util.List> listImpl() default ArrayList.class;

	@SuppressWarnings("rawtypes")
	Class<? extends java.util.Set> setImpl() default HashSet.class;

	@SuppressWarnings("rawtypes")
	Class<? extends java.util.Map> mapImpl() default HashMap.class;

	/**
	 * Rules for excluding some properties from getter code generation. If at
	 * least one of the matcher matches the property, no getter is generated.
	 * 
	 * @return the element matchers
	 */
	Matcher[] gettersExcludeRules() default {};

	/**
	 * Maps annotations from source class properties to target class getters.
	 * 
	 * @return the annotation mappings.
	 */
	AnnotationMapping[] annotationMappingsForGetters() default {};

	/**
	 * 
	 * @return whether to generate setters at all
	 */
	boolean generateSetters() default true;

	/**
	 * Rules for excluding some properties from setter code generation. If at
	 * least one of the matcher matches the property, no setter is generated.
	 * <p>
	 * For example you might annotate derived properties with a @Derived
	 * annotation and than exclude those properties from setter generation.
	 * 
	 * @return the element matchers
	 */
	Matcher[] settersExcludeRules() default {};

	Modifier[] fieldModifiers() default { Modifier.PRIVATE };

	Modifier[] getterModifiers() default { Modifier.PUBLIC };

	Modifier[] setterModifiers() default { Modifier.PUBLIC };

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
	 * Methods to create per property.
	 * 
	 * @return
	 */
	// Method[] methods() default {};

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
