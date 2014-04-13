package de.stefanocke.japkit.metaannotations;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.Properties.RuleSource;

/**
 * Meta-Annotation to generate constructors based on the properties of a class.
 * 
 * @author stefan
 * 
 */
public @interface Constructor {
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Constructor annotation, it must use this prefix
	 * 
	 * @return the prefix
	 */
	String _prefix() default "constructor";
	
	/**
	 * By default, this Constructor annotation is active an will generate constructors.
	 * To switch it on or of case by case, a Matcher can be used here. 
	 * The element on which the matcher is applied is the annotated class.
	 * 
	 * @return
	 */
	Matcher[] activation() default {};  

	Modifier[] modifiers() default { Modifier.PUBLIC };
	
	

	/**
	 * If this is true, the generated constructor is a copy constructor. That
	 * is, there is only one parameter and it has the same type as the object to
	 * be created.
	 * 
	 * @return
	 */
	boolean copyConstructor() default false;

	/**
	 * By default, the copy constructor will invoke the getters to get the
	 * properties of th object to be copied. If this is set to true, it uses
	 * field access instead.
	 * 
	 * @return
	 */
	boolean copyConstructorFieldAccess() default false;
	
	
	/**
	 * If copyConstructor is set, one can additionally generate a clone method that calls this copy constructor.
	 * @return
	 */
	boolean cloneMethodCallingCopyConstructor() default false;

	/**
	 * 
	 * @return true means, that for properties, where setters are available,
	 *         they are used to initialize those properties
	 */
	boolean callSetters() default true;

	/**
	 * Whether the constructor or init method shall create defensive copies
	 * before assigning the value to the field.
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
	 * <p>
	 * If "callSetters" is set to true, this option is ignored. Whether
	 * defensive copies are created is determined by the according Properties
	 * annotation then.
	 * 
	 * @return
	 */
	boolean assignDefensiveCopies() default false;
	
	Matcher[]  assignDefensiveCopiesAlsoFor() default {};
	
	@SuppressWarnings("rawtypes")
	Class<? extends java.util.List> listImpl() default ArrayList.class;
	
	@SuppressWarnings("rawtypes")
	Class<? extends java.util.Set> setImpl() default HashSet.class;
	
	@SuppressWarnings("rawtypes")
	Class<? extends java.util.Map> mapImpl() default HashMap.class;

	/**
	 * If set to to true, a separate method is created for the property
	 * assignments instead of assigning them in the constructor's code. The
	 * advantage is that this method can be "overriden" in the custom behavior
	 * class. The disadvantage is that you cannot assign final fields with this
	 * approach.
	 * <p>
	 * 
	 * 
	 * @return whether to create the init method
	 */
	boolean createInitMethod() default false;

	String initMethodName() default "init";

	/**
	 * 
	 * @return true means, the properties are based on the declared fields of
	 *         the  class. False means, they are based on the declared and
	 *         inherited getters of the  class.
	 */
	boolean fromFields() default true;
	
	
	/**
	 * Names of properties to be included. They must exist, otherwise an error
	 * is reported.
	 * 
	 * @return the property names
	 */
	String[] includeNames() default {};

	/**
	 * Determines the source elements for property rules (include rules, exclude
	 * rules, annotation mappings). By default, this the field of the property
	 * here.
	 * 
	 * @return
	 */
	RuleSource ruleSource() default RuleSource.FIELD;

	/**
	 * Rules for including properties. If at least one of the matcher matches
	 * the property, than it is included. By default, all properties are
	 * included.
	 * 
	 * @return the element matchers
	 */
	Matcher[] includeRules() default { @Matcher };

	/**
	 * Rules for excluding properties. If at least one of the matcher matches
	 * the property, than it is not included, even if the include rules say so.
	 * 
	 * @return
	 */
	Matcher[] excludeRules() default { @Matcher(srcModifiers=Modifier.STATIC)};

	/**
	 * Rules to decide which super constructors to call. For each super
	 * constructor, where at least one of the matcher matches, a constructor is
	 * generated that calls that super constructor. Note that only a subset of
	 * the @Matcher annotation values is meaningful for constructors. For
	 * example, you can check for presence of annotations, but you cannot check
	 * the type of the constructor.
	 * <p>
	 * By default, all super constructors are called.
	 * 
	 * @return
	 */
	Matcher[] superConstructors() default { @Matcher };

	/**
	 * The annotation mappings to put annotations on the generated constructor.
	 * The source element is the called super constructor (might be the default
	 * constructor).
	 */
	AnnotationMapping[] annotationMappings() default {};

	@interface List {
		Constructor[] value();
	}
}
