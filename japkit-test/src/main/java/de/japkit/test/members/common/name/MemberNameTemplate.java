package de.japkit.test.members.common.name;

import javax.lang.model.element.TypeElement;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.test.members.common.source.SourceExample;

/**
 * Member names can be copied from the template, set as annotation value (name)
 * or set by evaluating an expression (nameExpr or using $...$-syntax).
 * <p>
 * The examples here are for fields but apply to methods and inner classes as
 * well. They do not apply to constructors, since they don't have an own name.
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class MemberNameTemplate {

	/**
	 * The name of the generated field is copied from the template. Here
	 * "someString1".
	 */
	String someString1;

	/**
	 * The name of the generated field is determined by the annotation value
	 * name. Here it is "someString2".
	 */
	@Field(name = "someString2")
	String nameFromAV;

	/**
	 * The name of the generated field is determined by evaluating the Java EL
	 * expression given by nameExpr.
	 * <p>
	 * Here it is "memberNameExample1", since the src is the {@link TypeElement}
	 * for the annotated class {@link SourceExample}, and its
	 * {@link TypeElement#getSimpleName()} is "SourceExample".
	 */
	@Field(nameExpr = "#{src.simpleName.toFirstLower}1")
	String nameFromExpr;

	/**
	 * The name of the generated field is determined by evaluating the Java EL
	 * expression given by an $-delimited Java EL expression in the template for
	 * the member. "_" must be used instead of ".". Note that this allows only
	 * for simple expressions.
	 * <p>
	 * TODO: Shouldn't we apply toFirstLower here automatically?
	 * <p>
	 * The resulting name is "memberNameExample2".
	 */
	String $src_simpleName_toFirstLower$2;

	/**
	 * Here, toFirstUpper will be applied automatically, since the expression is
	 * not at the beginning of the member name. (For demonstration purposes we
	 * apply toFirstLower, to transform "MemberNameExample" into
	 * "memberNameExample"). The resulting name is "prefixMemberNameExample2".
	 */
	String prefix$src_simpleName_toFirstLower$2;

	/**
	 * Src is always implicit in expressions and can be omitted.
	 * <p>
	 * TODO: Shouldn't we apply toFirstLower here automatically?
	 * <p>
	 * The resulting name is "memberNameExample3".
	 */
	String $simpleName_toFirstLower$3;

	/**
	 * Here, the src is set to the list of fields of the {@link TypeElement} for
	 * the annotated class {@link SourceExample}. Thus, there is a field
	 * generated for every field in this list. The src in the name expression is
	 * each field in that list. Thus, the resulting fields are "srcField1Copy"
	 * and "srcField2Copy".
	 */
	@Field(src = "#{src.enclosedElements.stream().filter(e -> e.kind == 'FIELD').toList()}", nameExpr = "#{src.simpleName}Copy")
	String nameFromExprWithSrcCollection;

}
