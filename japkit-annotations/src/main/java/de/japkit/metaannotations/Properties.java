package de.japkit.metaannotations;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.classselectors.None;

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
	 * Expression that yields a collection with the names of properties to be included. They must exist in the source class,
	 * otherwise an error is reported.
	 * <p>
	 * This expression might also yield a list of classes. In this case, the simple names of these classes are used. This allows
	 * to refer to properties in a compile-time safe and code completion friendly way. However, there is no standard annotation provides
	 * for generating those "property reference classes" but that can easily be done with something like @InnerClass(src="properties").
	 * 
	 * @return the property names
	 */
	String includeNamesExpr() default "";
	
	String includeNamesLang() default "";
	
	/**The includeNames given by includeNamesExpr must all start with this prefix and this prefix is removed to get the property name.*/
	String includeNamesPrefix() default ""; 
	
	/**The includeNames given by includeNamesExpr must all end with this suffix and this suffix is removed to get the property name.*/
	String includeNamesSuffix() default "_";

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

}
