package de.japkit.test.members.common.body;

import javax.validation.constraints.NotNull;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.CodeFragment;

/**
 * This template shows how to generate the code blocks that made up the body of
 * methods or constructors. It also shows how to generate initializers for
 * fields.
 * <p>
 * In both cases, there is no syntax or structure enforced for then generated
 * code by japkit. Basically, it is just free text templating. However, there is
 * support for adding import statements to the generated class to avoid use of
 * fully qualified class names in the code templates.
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class BodyTemplate {

	/**
	 * This will generate a statement that checks for null, if the given source
	 * element has the {@link NotNull} annotation.
	 * <p>
	 * Since the code has multiple lines, you need at least the
	 * <code>&#60;pre&#62;</code> tag to keep the line breaks and indentations.
	 * The <code>&#60;ul&#62;</code> / <code>&#60;li&#62;</code> notation is for
	 * keeping this javadoc comment formatted as it is in the IDE. So,
	 * <code>&#60;li&#62;japkit.code</code> is an alternative to
	 * <code>&#64;japkit.code</code> when dealing with multiline code.
	 * <ul>
	 * <li>japkit.code
	 * 
	 * <pre>
	 * if (#{name} == null) { 
	 * 	throw new IllegalArgumentException("#{name} must not be null.");
	 * }
	 * </pre>
	 * </ul>
	 */
	@CodeFragment()
	class notNullCheck {
	}

}
