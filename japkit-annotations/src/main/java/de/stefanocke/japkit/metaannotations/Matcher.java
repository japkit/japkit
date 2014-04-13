package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Annotation;

import javax.lang.model.element.Modifier;

/**
 * A Matcher is a predicate over an element. Used at several places to decide
 * whether to include or exclude the regarding element in some kind of
 * processing.
 * 
 * @author stefan
 * 
 */
public @interface Matcher {

	/**
	 * All of those modifiers must be present at the source element for the rule
	 * to apply.
	 * 
	 * @return the modifiers
	 */
	Modifier[] srcModifiers() default {};

	/**
	 * All of those annotations must be present on the source element for the
	 * rule to apply.
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] srcAnnotations() default {};

	/**
	 * If any of those annotations is present on the source element, the rule is
	 * not applied.
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] srcAnnotationsNot() default {};

	/**
	 * All of those annotations must be present on the enclosing element of the
	 * source element for the rule to apply.
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] enclosingAnnotations() default {};

	/**
	 * If any of those annotations is present on the enclosing element of the
	 * source element, the rule is not applied.
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] enclosingAnnotationsNot() default {};

	/**
	 * The source element's type must be a subtype of this type for the rule to
	 * apply.
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * 
	 * @return the type
	 */
	Class<?> srcType() default Object.class;
	
	/**
	 * Same semantics as srcType, but in case of a generic collection, the collection's element type is considered.
	 * In case of a map, the map's value type is considered. If it is neither a collection nor a map, the source
	 * element's type is considered as is.
	 *  
	 * @return the type
	 */
	Class<?> srcSingleValueType() default Object.class;
	
	/**
	 * The source element's type must belong to at least one of the given categories.
	 * An empty list means, all types match. 
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * 
	 * @return the categories
	 */
	TypeCategory[] srcTypeCategory() default {};
	
	/**
	 * Same semantics as srcTypeCategory, but in case of a generic collection, the collection's element type is considered.
	 * In case of a map, the map's value type is considered. If it is neither a collection nor a map, the source
	 * element's type is considered as is.
	 *  
	 * @return the type categories
	 */
	TypeCategory[] srcSingleValueTypeCategory() default {};

	/**
	 * The source element's must not belong to any of the given categories. 
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * 
	 * @return the type categories
	 */
	TypeCategory[] srcTypeCategoryNot() default {};
	
	/**
	 * Same semantics as srcTypeCategoryNot, but in case of a generic collection, the collection's element type is considered.
	 * In case of a map, the map's value type is considered. If it is neither a collection nor a map, the source
	 * element's type is considered as is.
	 *  
	 * @return the type categories
	 */
	TypeCategory[] srcSingleValueTypeCategoryNot() default {};
	
	/**
	 * The source element's type must have those annotations for the rule to
	 * apply
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * <p>
	 * Example: "Apply this mapping, if the target type is a @ValueObject"
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] srcTypeAnnotations() default {};
	
	/**
	 * Same semantics as srcTypeAnnotations, but in case of a generic collection, the collection's element type is considered.
	 * In case of a map, the map's value type is considered. If it is neither a collection nor a map, the source
	 * element's type is considered as is.
	 *  
	 * @return the annotations
	 */
	Class<? extends Annotation>[] srcSingleValueTypeAnnotations() default {};
	

	/**
	 * The source element's type must have at least one type argument and the
	 * type of the first argument must have all the annotations given here. This
	 * is for example useful for Collection types.
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * <p>
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] srcTypeArg0Annotations() default {};

	/**
	 * The source element's type must have at least two type arguments and the
	 * type of the second argument must have all the annotations given here.
	 * This is for example useful for Map types.
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * <p>
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] srcTypeArg1Annotations() default {};

	/**
	 * Condition expression. If not empty, it must evaluate to true for the rule
	 * to apply. The ELContext provides the source element as the variable
	 * "element". 
	 * 
	 * @return the expression.
	 */
	String condition() default "";
	
	/**
	 * 
	 * @return language for the condition expression. Defaults to Java EL.
	 */
	String conditionLang() default "";
	
	/**
	 * Constraints to be evaluated when the matcher matches an element.
	 */
	Constraint[] constraints() default {};

}
