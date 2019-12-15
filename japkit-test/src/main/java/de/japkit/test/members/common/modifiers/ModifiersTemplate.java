package de.japkit.test.members.common.modifiers;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.InnerClass;
import de.japkit.metaannotations.Method;

/**
 * ModifiersTrigger can either be copied from the template or set conditionally.
 * <p>
 * The examples here are mainly for fields and methods but apply to constructors
 * and inner classes as well.
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public abstract class ModifiersTemplate {

	/**
	 * ModifiersTrigger are copied to the generated element.
	 * <p>
	 * Here: public
	 */
	public String publicField;

	/**
	 * ModifiersTrigger are copied to the generated element.
	 * <p>
	 * Here: private
	 */
	private String privateField;

	/**
	 * ModifiersTrigger are copied to the generated element.
	 * <p>
	 * Here: public static
	 */
	public static int publicStaticField;

	/**
	 * ModifiersTrigger are copied to the generated element.
	 * <p>
	 * Here: transient volatile
	 */
	transient volatile int transientVolatileField;

	/**
	 * For final fields, code for initialization needs to be provided.
	 * <p>
	 * Here, the String literal "initialValue" is generated.
	 */
	@Field(initCode = "\"initialValue\"")
	final String finalField = "dummy";

	/**
	 * Visibilities can also be set dynamically.
	 * <p>
	 * Here, the generate field is made private based on a boolean expression.
	 */
	@Field(privateCond = "#{true}")
	String dynamicallyPrivateField;

	/**
	 * The expressions for setting modifiers dynamically have precedence over
	 * the according modifiers from the template.
	 * <p>
	 * Here, the generated field is not public, since publicCond evaluates to
	 * false. The field is still static, like given by the template.
	 */
	@Field(publicCond = "#{false}")
	public static String dynamicallyNonPublicStaticField;

	/**
	 * The abstract modifier is removed from methods, if they have rules for
	 * generating a code body. This allows to write method templates without a
	 * dummy method body.
	 * <p>
	 * Here, the generated method is not abstract, since bodyCode is set.
	 */
	@Method(bodyCode = "return null;")
	public abstract String notAbstractMethod();

	/**
	 * To support method templates without a dummy method body, also the class
	 * template containing them needs to be abstract. Thus, the abstract
	 * modifier is by default removed from generated classes and inner classes.
	 * <p>
	 * Here, the generated inner class is not abstract.
	 */
	@InnerClass
	public abstract class NonAbstractInnerClass {

	}

	/**
	 * To keep the abstract modifier for a generated class or inner class,
	 * keepAbstract must be set to true.
	 */
	@InnerClass(keepAbstract = true)
	public abstract class AbstractInnerClass {

	}
}
