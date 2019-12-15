package de.japkit.test.members.constructor;

import javax.lang.model.element.TypeElement;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.functions.SrcType;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Constructor;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Param;
import de.japkit.test.members.MembersExample;
import de.japkit.test.members.common.annotations.AnnotationsTemplate;
import de.japkit.test.members.common.body.BodyTemplate;
import de.japkit.test.members.common.condition.ConditionTemplate;
import de.japkit.test.members.common.modifiers.ModifiersTemplate;
import de.japkit.test.members.common.parameters.ParameterTemplate;
import de.japkit.test.members.common.source.SourceTemplate;

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
 * <li>For more details on how to generate the parameters of the constructor,
 * see {@link ParameterTemplate}.
 * <li>For more details on how to generate the body code of the constructor, see
 * {@link BodyTemplate}.
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
	@Constructor
	public ConstructorTemplate() {
	}

	/**
	 * A constructor that has the fields of the annotated class
	 * ({@link MembersExample}) as parameters.
	 */
	public ConstructorTemplate(@Param(srcFun = fields.class) SrcType $name$) {
	}

	/**
	 * A function to get the fields of a {@link TypeElement}.
	 */
	@Function(expr = "#{enclosedElements}", filter = "#{kind == 'FIELD'}")
	class fields {
	}
}
