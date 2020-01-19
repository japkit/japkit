package de.japkit.test.members.common.condition;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.InnerClass;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;

/**
 * Class members can be generated conditionally by setting cond or condFun.
 * <p>
 * In this template, the member are generated if the trigger annotation value
 * shallGenerateMembers, which is provided as EL variable, is set to true. Any
 * boolean expressions or functions can be used as conditions.
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public abstract class ConditionTemplate {

	/**
	 * This field is generated if cond evaluates to true. This is the case when
	 * the trigger annotation value shallGenerateMembers is set to true.
	 */
	@Field(cond = "#{shallGenerateMembers}")
	public String someField1;

	/**
	 * The condition is evaluated before the src variable (see
	 * {@link de.japkit.test.members.common.source.SourceTemplate}) is set. So
	 * if the src variable is used in the condition it will be the one of the
	 * surrounding template.
	 * <p>
	 * So, "someField2" will be generated, if the src name is
	 * "ConditionExampleTrue" which is exactly the case if that is the name of
	 * the annotated class, which is the src of this {@link ConditionTemplate}.
	 */
	@Field(cond = "#{src.simpleName == 'ConditionExampleTrue'}", src = "#{'fooBar'}")
	public String someField2;

	/**
	 * This method is generated if cond evaluates to true. This is the case when
	 * the trigger annotation value shallGenerateMembers is set to true.
	 */
	@Method(cond = "#{shallGenerateMembers}", bodyCode = "return null;")
	public abstract String someMethod();

	/**
	 * This inner class is generated if the function someFunction evaluates to
	 * true.
	 */
	@InnerClass(condFun = someFunction.class)
	public static class SomeInnerClass {

	}

	/**
	 * This function evaluates to true if the trigger annotation value
	 * shallGenerateMembers is set to true.
	 */
	@Function(expr = "#{shallGenerateMembers}")
	class someFunction {
	};

	/**
	 * If multiple members have the same condition, they can be grouped in a
	 * template with that condition.
	 */
	@Template(cond = "#{shallGenerateMembers}")
	abstract class SomeTemplate {
		public String someFieldInTemplate;

		@Method(bodyCode = "return null;")
		public abstract String someMethodInTemplate();

	}
}
