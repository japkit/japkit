package de.stefanocke.japkit.metaannotations;

import javax.lang.model.element.Element;
import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * Annotation to add a method to a generated class.
 * 
 * @author stefan
 * 
 */
public @interface Method {
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Method annotation, it must use this prefix.
	 * 
	 * @return
	 */
	String _prefix() default "<method>";

	/**
	 * By default, only one method is generated by that annotation. To generate
	 * multiple methods with similar attributes you can set an EL expression
	 * here. It must be an {@link Iterable} over {@link Element}. For each of
	 * those elements, a method is generated. The element is also used as rule
	 * source element for all matchers and EL expressions in the following. (For
	 * example, this allows for a nameExpr that determines the name depending on
	 * that element.)
	 * 
	 * @return
	 */
	String iterator() default "";

	/**
	 * 
	 * @return the language of the iterator expression. Defaults to Java EL.
	 */
	String iteratorLang() default "";

	/**
	 * EL Variables within the scope of the method. The root property "element"
	 * refers to the enclosing class or to the current element of the iterator.
	 * 
	 * @return
	 */
	Var[] vars() default {};

	/**
	 * By default, this method annotation is active an will generate a method.
	 * To switch it on or of case by case, a Matcher can be used here. The
	 * element on which the matcher is applied is the annotated class.
	 * 
	 * @return
	 */
	Matcher[] activation() default {};

	/**
	 * 
	 * @return the name of the method. If not empty, nameExpr is ignored.
	 */
	String name() default "";

	/**
	 * For more complex cases: a Java EL expression to generate the name of the
	 * method. The root property "element" refers to the enclosing class or to
	 * the current element of the iterator..
	 * 
	 * @return
	 */
	String nameExpr() default "";

	/**
	 * 
	 * @return the language of the name expression. Defaults to Java EL.
	 */
	String nameLang() default "";

	/**
	 * 
	 * @return the return type of the method.
	 */
	Class<?> returnType() default None.class;

	Class<?>[] returnTypeArgs() default {};

	/**
	 * 
	 * @return the modifiers of the method
	 */
	Modifier[] modifiers() default {};

	/**
	 * How to map annotations of the source element (???) to the method
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	AnnotationMapping[] annotationMappings() default {};

	/**
	 * 
	 * @return the parameters of the method
	 */
	Param[] parameters() default {};

	/**
	 * Classes to imported for the method body. Allows to use short class names
	 * in the body expr. The imports are only added if they don't conflict with
	 * others. Otherwise, it's an error. TODO: Instead of an error , we could
	 * replace the short name in the body by the fqn.
	 * 
	 * @return
	 */
	Class<?>[] imports() default {};

	/**
	 * 
	 * @return a Java EL expression to generate the body. The root property
	 *         "element" refers to the generated method.
	 */
	String bodyExpr() default "";

	/**
	 * 
	 * @return the language of the body expression. Default is Java EL.
	 */
	String bodyLang() default "";
	
	/**
	 * The delegate methods to create. The delegate is the return value of the generated method.
	 * 
	 * @return
	 */
	DelegateMethods[] delegateMethods() default {};

	@interface List {
		Method[] value();
	}
}
