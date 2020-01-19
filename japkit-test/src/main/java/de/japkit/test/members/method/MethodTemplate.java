package de.japkit.test.members.method;

import java.util.Objects;

import javax.lang.model.element.TypeElement;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.functions.SrcType;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.CodeFragment;
import de.japkit.metaannotations.Constructor;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Getter;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Setter;
import de.japkit.test.members.common.annotations.AnnotationsTemplate;
import de.japkit.test.members.common.condition.ConditionTemplate;
import de.japkit.test.members.common.modifiers.ModifiersTemplate;
import de.japkit.test.members.common.name.MemberNameTemplate;
import de.japkit.test.members.common.source.SourceTemplate;
import de.japkit.test.members.common.type.TypeTemplate;
import de.japkit.test.members.constructor.ConstructorTemplate;
import de.japkit.test.members.field.FieldTemplate;

/**
 * This template shows how to generate methods.
 * <p>
 * The examples shown here for generating the parameters and the code body also
 * apply to constructors. See {@link ConstructorTemplate}.
 * <p>
 * In case of the code body, there is no syntax or structure enforced for then
 * generated code by japkit. Basically, it is just free text templating.
 * However, there is support for adding import statements to the generated class
 * to avoid use of fully qualified class names in the code templates.
 * <ul>
 * <li>For more details on how to generate methods conditionally, see
 * {@link ConditionTemplate}.
 * <li>For more details on how to set the src and how to generate multiple
 * methods from one method template, see {@link SourceTemplate}.
 * <li>For more details on how to set the modifiers of the method, see
 * {@link ModifiersTemplate}.
 * <li>For more details on how to set the annotations of the method or the
 * parameters, see {@link AnnotationsTemplate}.
 * <li>For more details on how to set the return type of the method, see
 * {@link TypeTemplate}.
 * <li>For more details on how to set the name of the method, see
 * {@link MemberNameTemplate}.
 * </ul>
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class MethodTemplate {

	/**
	 * As shown in {@link FieldTemplate}, the fields are copied from the
	 * annotated class. They are used later to generate some meaningful methods.
	 */
	@Field(srcFun = fields.class, getter = @Getter, setter = @Setter)
	private SrcType $name$;

	/**
	 * Generates a method with fixed parameter list, name and return type.
	 * <p>
	 * Since the body code is simple, it can be easily written as bodyCode
	 * annotation value.
	 * <p>
	 * Since the method has a non-void return type, the method template returns
	 * 0 as dummy value. Alternatively, the method template can be made
	 * abstract.
	 * <p>
	 * To demonstrate the usage of surrounding code fragments, the code body is
	 * wrapped into a try-catch that catches every Exception and rethrows it is
	 * RuntimeException. See {@link rethrowAsRuntimeException}.
	 */
	@Method(bodyCode = "return number1 + number2;", bodySurroundingFragments = "rethrowAsRuntimeException")
	public int add(int number1, int number2) {
		return 0;
	};

	/**
	 * Generates a hashCode method based on {@link Objects#hash(Object...)}.
	 * <ul>
	 * <li>The method template is annotated with {@link Override}. This
	 * annotation will be copied onto the generated method.
	 * <li>To not have to use the qualified name java.util.Objects, it is
	 * "imported". Japkit will take care of adding the import statement to the
	 * generated class.
	 * <li>When generating the code body, it is necessary to iterate over the
	 * fields, since the result shall look like
	 * <code>return Objects.hash(field1, field2, field3, ...);</code> For this,
	 * bodyIterator is used, which calls the {@link fields} function here to
	 * determine the collection to iterate on. bodyCode is just the name of the
	 * field. The list of fields is separated by "," (bodySeparator) and
	 * surrounded by <code>"return Objects.hash("</code>
	 * (bodyBeforeIteratorCode) and <code>")"</code> (bodyAfterIteratorCode).
	 * </ul>
	 */
	@Method(
		imports = Objects.class,
		bodyIteratorFun = fields.class,
		bodyBeforeIteratorCode = "return Objects.hash(",
		bodyCode = "#{name}",
		bodySeparator = ", ",
		bodyLinebreak = false,
		bodyAfterIteratorCode = ");")
	@Override
	public int hashCode() {
		return 0;
	}

	/**
	 * Generates an equals method based on
	 * {@link Objects#equals(Object, Object)}.
	 * <p>
	 * This is quite similar to generating {@link #hashCode()}: It iterates over
	 * the fields and adds some code for each field. But the code to be
	 * generated has mutltiple lines, which is impossible or at least unreadable
	 * when put into annotation values. Thus, as an alternative syntax,
	 * bodyBeforeIteratorCode, bodyCode, bodyAfterIteratorCode and others can be
	 * put into the javadoc comment. Please note the special syntax:
	 * <ul>
	 * <li>The prefix <code>japkit.</code> is necessary to make the "tags"
	 * recognizable to japkit at all.
	 * <li>Since the bodyBeforeIteratorCode has multiple lines, the
	 * <code>&#60;pre&#62;</code> tag is required to keep the line breaks and
	 * indentations.
	 * <li>The <code>&#60;ul&#62;</code> / <code>&#60;li&#62;</code> notation is
	 * for keeping this javadoc comment formatted as it is in the IDE.
	 * <li><code>&#60;li&#62;japkit.code</code> is an alternative to
	 * <code>&#64;japkit.code</code>. It has proven to be more resistant to
	 * re-formatting applied by the IDE (especially indentation).
	 * </ul>
	 * Note that this syntax is not only preferable for multiline code, but also
	 * if your are struggling with escaping of quotation marks in the code.
	 * <p>
	 * Also note that the complete <code>&#60;ul&#62;</code> Block will be
	 * removed by japkit when the method comment is generated. So, it is only in
	 * the template, where it belongs.
	 * <ul>
	 * <li>japkit.bodyBeforeIteratorCode
	 * 
	 * <pre>
	 * if (!(obj instanceof #{genClass.asType().code})) {
	 *  return false;
	 * }
	 * #{genClass.asType().code} other = (#{genClass.asType().code}) obj;
	 * return
	 * </pre>
	 * 
	 * <li>japkit.bodyCode Objects.equals(#{name}, other.#{name})
	 * <li>japkit.bodyAfterIteratorCode ;
	 * </ul>
	 */
	@Method(imports = Objects.class, bodyIteratorFun = fields.class, bodySeparator = " &&", bodyIndentAfterLinebreak = true)
	@Override
	public boolean equals(Object obj) {
		return true;
	}

	/**
	 * A code fragment that that catches every Exception and rethrows it is
	 * RuntimeException. To be used as surrounding fragment in
	 * {@link Method#bodySurroundingFragments()},
	 * {@link Constructor#bodySurroundingFragments()} or
	 * {@link CodeFragment#surroundingFragments()}. The code to be surrounded is
	 * provided as EL variable 'surrounded' to the fragment.
	 * <ul>
	 * <li>japkit.code
	 * 
	 * <pre>
	 * try {
	 * 	#{surrounded}
	 * } catch (Exception e) {
	 * 	throw new RuntimeException(e);
	 * }
	 * </pre>
	 * </ul>
	 */
	@CodeFragment
	class rethrowAsRuntimeException {
	}

	/**
	 * A function to get the fields of a {@link TypeElement}.
	 */
	@Function(expr = "#{enclosedElements}", filter = "#{kind == 'FIELD'}")
	class fields {
	}
}
