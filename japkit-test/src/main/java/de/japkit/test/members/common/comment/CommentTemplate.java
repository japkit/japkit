package de.japkit.test.members.common.comment;

import javax.lang.model.element.Element;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.functions.SrcType;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.test.members.common.source.SourceTemplate;

/**
 * Comments for members can be set by evaluating the commentExpr annotation
 * value or by evaluating the comment of the template.
 * <p>
 * The examples here are for fields but apply to methods and inner classes as
 * well.
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class CommentTemplate {

	/**
	 * This comment is just copied as it is.
	 */
	String someString1;

	/**
	 * Since the comment is not just copied, but evaluated as a Java EL
	 * expression, it is for example possible to use the name of the generated
	 * class: #{src.simpleName}.
	 * <p>
	 * This is also a nice debugging tool for showing the result expressions:
	 * #{src.enclosedElements.stream().filter(e -> e.kind == 'FIELD').toList()}
	 */
	String someString2;

	/**
	 * When the template's comment shall not be used for generating the comment,
	 * the annotation value commentExpr can be used instead.
	 */
	@Field(commentExpr = "The real comment.")
	String someString3;

	/**
	 * The comment can also be copied from the source element. The src variable
	 * must be an {@link Element} for this. See {@link SourceTemplate} for more
	 * details.
	 * <p>
	 * Comments from source elements are usually not available during
	 * incremental build.
	 */
	@Field(src = "#{src.enclosedElements.stream().filter(e -> e.kind == 'FIELD').toList()}", commentFromSrc = true)
	SrcType $name$Copy;

}
