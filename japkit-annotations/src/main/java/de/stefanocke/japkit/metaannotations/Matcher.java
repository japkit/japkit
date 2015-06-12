package de.stefanocke.japkit.metaannotations;

import java.lang.annotation.Annotation;

import javax.lang.model.element.ElementKind;
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
	 * Optional expression to determine the element to which the checks of the matcher are applied to. By default this is the current source element (#{src}). 
	 * @return the expression
	 */
	String src() default "";

	/**
	 * As an alternative to the src expression, a function can be called to determine the source object.
	 * 
	 * @return
	 */
	Class<?>[] srcFun() default {};
	
	/**
	 * 
	 * @return language for the src expression. Defaults to Java EL.
	 */
	String srcLang() default "";
	
	
	/**
	 * If set, the src element must have this simpleName.
	 * @return
	 */
	String name() default "";
	
	/**
	 * If set, the source element must have a name that is amongst the names given by the expression. The expression must evaluate to an Iterable of 
	 * CharSequence or to an Iterable of Element. In the latter case, the simple names of the elements are considered.
	 * @return
	 */
	String nameIn() default "";
	
	String nameInLang() default "";
	
	/**
	 * If set, the source element must have a name that is not amongst the names given by the expression. The expression must evaluate to an Iterable of 
	 * CharSequence or to an Iterable of Element. In the latter case, the simple names of the elements are considered.
	 * @return
	 */
	String nameNotIn() default "";
	
	String nameNotInLang() default "";
	
	/**
	 * All of those modifiers must be present at the source element for the rule
	 * to apply.
	 * 
	 * @return the modifiers
	 */
	Modifier[] modifiers() default {};

	/**
	 * If any of those modifiers is present on the source element, the rule is
	 * not applied.
	 * 
	 * @return
	 */
	Modifier[] modifiersNot() default {};

	/**
	 * If non-empty, the element must have one of the given kinds to match.
	 * 
	 * @return
	 */
	ElementKind[] kind() default {};

	/**
	 * All of those annotations must be present on the source element for the
	 * rule to apply.
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] annotations() default {};

	/**
	 * If any of those annotations is present on the source element, the rule is
	 * not applied.
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] annotationsNot() default {};

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
	 * If the source element is declared by any of those classes, the rule does
	 * not apply.
	 * <p>
	 * For example, this is useful , when considering a collection of inherited
	 * elements to filter out the ones that come from some common superclasses.
	 * 
	 * @return
	 */
	Class<?>[] notDeclaredBy() default {};

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
	Class<?> type() default Object.class;

	/**
	 * Same semantics as srcType, but in case of a generic collection, the
	 * collection's element type is considered. In case of a map, the map's
	 * value type is considered. If it is neither a collection nor a map, the
	 * source element's type is considered as is.
	 * 
	 * @return the type
	 */
	Class<?> singleValueType() default Object.class;

	/**
	 * The source element's type must belong to at least one of the given
	 * categories. An empty list means, all types match.
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * 
	 * @return the categories
	 */
	TypeCategory[] typeCategory() default {};

	/**
	 * Same semantics as srcTypeCategory, but in case of a generic collection,
	 * the collection's element type is considered. In case of a map, the map's
	 * value type is considered. If it is neither a collection nor a map, the
	 * source element's type is considered as is.
	 * 
	 * @return the type categories
	 */
	TypeCategory[] singleValueTypeCategory() default {};

	/**
	 * The source element's must not belong to any of the given categories.
	 * <p>
	 * For fields, the type of the field is considered. For methods, the return
	 * type is considered. For other elements, the type as provided by
	 * Element.asType is considered.
	 * 
	 * @return the type categories
	 */
	TypeCategory[] typeCategoryNot() default {};

	/**
	 * Same semantics as srcTypeCategoryNot, but in case of a generic
	 * collection, the collection's element type is considered. In case of a
	 * map, the map's value type is considered. If it is neither a collection
	 * nor a map, the source element's type is considered as is.
	 * 
	 * @return the type categories
	 */
	TypeCategory[] singleValueTypeCategoryNot() default {};

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
	Class<? extends Annotation>[] typeAnnotations() default {};

	/**
	 * Same semantics as srcTypeAnnotations, but in case of a generic
	 * collection, the collection's element type is considered. In case of a
	 * map, the map's value type is considered. If it is neither a collection
	 * nor a map, the source element's type is considered as is.
	 * 
	 * @return the annotations
	 */
	Class<? extends Annotation>[] singleValueTypeAnnotations() default {};

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
	Class<? extends Annotation>[] typeArg0Annotations() default {};

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
	Class<? extends Annotation>[] typeArg1Annotations() default {};

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
