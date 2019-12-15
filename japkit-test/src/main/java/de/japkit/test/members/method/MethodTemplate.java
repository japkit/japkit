package de.japkit.test.members.method;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.test.members.common.annotations.AnnotationsTemplate;
import de.japkit.test.members.common.body.BodyTemplate;
import de.japkit.test.members.common.condition.ConditionTemplate;
import de.japkit.test.members.common.modifiers.ModifiersTemplate;
import de.japkit.test.members.common.name.MemberNameTemplate;
import de.japkit.test.members.common.parameters.ParameterTemplate;
import de.japkit.test.members.common.source.SourceTemplate;
import de.japkit.test.members.common.type.TypeTemplate;

/**
 * This template shows how to generate methods.
 * <ul>
 * <li>For more details on how to generate methods conditionally, see
 * {@link ConditionTemplate}.
 * <li>For more details on how to set the src and how to generate multiple
 * methods from one method template, see {@link SourceTemplate}.
 * <li>For more details on how to set the modifiers of the method, see
 * {@link ModifiersTemplate}.
 * <li>For more details on how to set the annotations of the method, see
 * {@link AnnotationsTemplate}.
 * <li>For more details on how to set the return type of the method, see
 * {@link TypeTemplate}.
 * <li>For more details on how to set the name of the method, see
 * {@link MemberNameTemplate}.
 * <li>For more details on how to generate the parameters of the method, see
 * {@link ParameterTemplate}.
 * <li>For more details on how to generate the body code of the method, see
 * {@link BodyTemplate}.
 * </ul>
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class MethodTemplate {

}
