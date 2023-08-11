package de.japkit.test.members.constructor;

import java.util.Objects;

import javax.lang.model.element.TypeElement;
import jakarta.validation.constraints.NotNull;

import org.apache.commons.lang3.StringUtils;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.functions.SrcType;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.CodeFragment;
import de.japkit.metaannotations.Constructor;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Param;
import de.japkit.test.members.MembersExample;
import de.japkit.test.members.common.annotations.AnnotationsTemplate;
import de.japkit.test.members.common.condition.ConditionTemplate;
import de.japkit.test.members.common.modifiers.ModifiersTemplate;
import de.japkit.test.members.common.source.SourceTemplate;
import de.japkit.test.members.method.MethodTemplate;

/**
 * This template shows how to generate constructors.
 * <ul>
 * <li>For more details on how to generate constructors conditionally, see
 * {@link ConditionTemplate}.
 * <li>For more details on how to set the src and how to generate multiple
 * constructors from one constructor template, see {@link SourceTemplate}.
 * <li>For more details on how to set the modifiers of the constructor, see
 * {@link ModifiersTemplate}.
 * <li>For more details on how to set the annotations of the constructor, see
 * {@link AnnotationsTemplate}.
 * <li>For more examples on how to generate the parameters and the body code of
 * the constructor, see also {@link MethodTemplate}.
 * </ul>
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class ConstructorTemplate {
	/**
	 * A parameterless constructor. When it is generated in the target class,
	 * the name will we be adjusted accordingly.
	 * <p>
	 * The {@link Constructor} annotation is required for disambiguation when
	 * generating a default constructor.
	 */
	@Constructor(bodyCode = "this.field1 = 5;")
	public ConstructorTemplate() {
	}

	/**
	 * For constructors with at least one parameter, the {@link Constructor}
	 * annotation is not necessary.
	 * 
	 * @japkit.bodyCode this.field2 = field2;
	 */
	public ConstructorTemplate(String field2) {
	}

	/**
	 * A constructor that has the fields of the annotated class
	 * ({@link MembersExample}) as parameters and assigns them to the according
	 * generated fields.
	 * <p>
	 * The parameter order depends on the result of
	 * {@link TypeElement#getEnclosedElements()}, which is used in
	 * {@link fields} function. Usually, this will be the same order as in the
	 * source code of {@link ConstructorExample}. However, during incremental
	 * build in Eclipse, you may sometimes experience a different order. If this
	 * happens, please do a clean build.
	 * 
	 * @see <a href="https://bugs.eclipse.org/bugs/show_bug.cgi?id=300408">
	 *      Eclipse Bug 300408</a>
	 * @see <a href="https://bugs.eclipse.org/bugs/show_bug.cgi?id=500589">
	 *      Eclipse Bug 500589</a>
	 */
	@Constructor(bodyIteratorFun = fields.class, bodyBeforeIteratorCode = "super();", bodyCode = "this.#{name} = #{name};")
	public ConstructorTemplate(@Param(srcFun = fields.class) SrcType $name$) {
	}

	/**
	 * The same as {@link #ConstructorTemplate(SrcType)}. But this time, a
	 * {@link CodeFragment} is called for generating the field assignment code.
	 * A CodeFragment is basically a function that creates code.
	 * <p>
	 * By using CodeFragments, arbitrary complex constructors and methods can be
	 * generated. But as in manual programming, it might be sometimes better to
	 * split them into multiple (private) methods then.
	 * <p>
	 * Note that there a important differences between a CodeFragment and a
	 * function that returns a string. For example, CodeFragments provide
	 * support for adding import statements to the generated class. Furthermore,
	 * they are evaluated lazily, when the generated class is finally written.
	 * So, do not use simple string functions when generating method or
	 * constructor bodies, but always CodeFragments.
	 */
	@Constructor(bodyIteratorFun = fields.class, bodyBeforeIteratorCode = "super();", bodyCode = "#{fieldAssignment()}")
	public ConstructorTemplate(int dummy, @Param(srcFun = fields.class) SrcType $name$) {
	}

	/**
	 * The CodeFragment to create a field assignment within the constructor. It
	 * expects the field (from the annotated class) as current src.
	 * <p>
	 * For generating the right hand side of the assignment, another code
	 * fragment is called: {@link fieldAssignmentRhs}.
	 */
	@CodeFragment(code = "this.#{name} = #{fieldAssignmentRhs()};")
	class fieldAssignment {
	}

	/**
	 * The right hand side of the field assignment. It expects the field (from
	 * the annotated class) as current src.
	 * <p>
	 * By default, the right hand side is just the name of the field / the
	 * parameter. For Strings, code for trimming is added. For {@link NotNull}
	 * annotated fields, a null check is added. So, for
	 * {@link ConstructorExample#field3}, the following code is generated:
	 * <code>Objects.requireNonNull(StringUtils.trimToNull(field3), "field3 must not be null.")</code>
	 */
	@CodeFragment(code = "#{name}", surroundingFragments = { "trimToNull", "nullCheck" })
	class fieldAssignmentRhs {
	}

	/**
	 * A code fragment that adds a null check to the field assignment if the
	 * field has a {@link NotNull} annotation. It expects the field (from the
	 * annotated class) as current src.
	 * <p>
	 * Since nullCheck is used as a fragment that surrounds other code, there is
	 * some special EL variable "surrounded" available here that contains the
	 * code to be surrounded.
	 * <p>
	 * If the field has no {@link NotNull} annotation, the fragments does
	 * nothing. For a surrounding fragment this means, the code to be surrounded
	 * is left as it is.
	 */
	@CodeFragment(
		condFun = hasNotNull.class,
		imports = Objects.class,
		code = "Objects.requireNonNull(#{surrounded}, \"#{name} must not be null.\")")
	class nullCheck {
	}

	/**
	 * A code fragment that trims Strings by
	 * {@link StringUtils#trimToNull(String)}. It expects the field (from the
	 * annotated class) as current src.
	 */
	@CodeFragment(condFun = isString.class, imports = StringUtils.class, code = "StringUtils.trimToNull(#{surrounded})")
	class trimToNull {
	}

	/**
	 * A boolean function that checks if the src element has a {@link NotNull}
	 * annotation.
	 */
	@Matcher(annotations = NotNull.class)
	class hasNotNull {
	}

	/**
	 * A boolean function that checks if the src element has String as type.
	 */
	@Matcher(type = String.class)
	class isString {
	}

	/**
	 * Copies the fields from {@link ConstructorExample}.
	 */
	@Field(srcFun = fields.class)
	SrcType $name$;

	/**
	 * A function to get the fields of a {@link TypeElement}.
	 */
	@Function(expr = "#{enclosedElements}", filter = "#{kind == 'FIELD'}")
	class fields {
	}
}
