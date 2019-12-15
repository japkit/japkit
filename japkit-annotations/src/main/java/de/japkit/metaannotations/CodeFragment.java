package de.japkit.metaannotations;

import java.lang.annotation.Documented;

/**
 * @author stefan
 */
@Documented
public @interface CodeFragment {

	/**
	 * By default, this rule is active. To switch it on or of case by case, a
	 * boolean expression can be used here.
	 * 
	 * @return
	 */
	String cond() default "";

	/**
	 * The expression language for the cond expression.
	 * 
	 * @return
	 */
	String condLang() default "";

	/**
	 * As an alternative to the cond expression, a boolean function can be
	 * called.
	 * 
	 * @return
	 */
	Class<?>[] condFun() default {};

	/**
	 * EL Variables within the scope of the code fragment.
	 * 
	 * @return
	 */
	Var[] vars() default {};

	/**
	 * Classes to imported for the code. Allows to use short class names in the
	 * body expr. The imports are only added if they don't conflict with others.
	 * Otherwise, it's an error.
	 * 
	 * @return
	 */
	Class<?>[] imports() default {};

	/**
	 * If the body shall contain some repetitive code, this expression can be
	 * used. It determines how often to repeat "code". The iteration variable is
	 * provided as "src" on the value stack.
	 * <p>
	 * A typical example is to iterate over the properties of the class, to
	 * generate methods like toString or equals / hashcode.
	 * 
	 * @return
	 */
	String iterator() default "";

	/**
	 * @return the language of the body iterator expression. Default is Java EL.
	 */
	String iteratorLang() default "";

	/**
	 * @return an expression to generate the code. The root property "src"
	 *         refers to the generated method or, if an iterator is used, the
	 *         current iterator element.
	 */
	String code() default "";

	/**
	 * If there is at least one of the given cases, where all matcher match, the
	 * according expression is use instead of expr. If no case matches, the
	 * default is expr.
	 * 
	 * @return
	 */
	Case[] cases() default {};

	/**
	 * @return if bodyIterator is set, this code is inserted between each
	 *         iteration of bodyExpr.
	 */
	String separator() default "";

	/**
	 * If true, a linebreak is inserted after the "before expression", the "body
	 * expression" and the "after expression". Note that this applies also, if
	 * no iterator is used. So, you can control whether the fragment end with a
	 * line break or whether it is in one line with the code that follows.
	 * 
	 * @return
	 */
	boolean linebreak() default true;

	boolean indentAfterLinebreak() default true;

	/**
	 * @return an expression for the code to be generated before the repetitive
	 *         code. Only rendered, if the iterator expression is set and does
	 *         not result in an empty iterator.
	 */
	String beforeIteratorCode() default "";

	/**
	 * @return an expression for the code to be generated after the repetitive
	 *         code. Only rendered, if the iterator expression is set and does
	 *         not result in an empty iterator.
	 */
	String afterIteratorCode() default "";

	/**
	 * @return an expression for the code to be generated if the iterator
	 *         expression is set but does result in an empty iterator.
	 */
	String emptyIteratorCode() default "";

	/**
	 * @return the language of the body expression. Default is Java EL.
	 */
	String lang() default "";

	/**
	 * @return names of the fragments to surround the code generated by this
	 *         fragment.
	 */
	String[] surroundingFragments() default {};

	/**
	 * @return names of the fragments to be inserted before the code generated
	 *         by this fragment.
	 */
	String[] beforeFragments() default {};

	/**
	 * @return names of the fragments to be inserted before the code generated
	 *         by this fragment.
	 */
	String[] afterFragments() default {};

}
