package de.japkit.test.members.field;

import java.lang.annotation.Documented;
import java.util.ArrayList;
import java.util.List;

import javax.lang.model.element.TypeElement;
import javax.validation.constraints.NotNull;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.functions.SrcType;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.CodeFragment;
import de.japkit.metaannotations.DefaultCase;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Getter;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Setter;
import de.japkit.metaannotations.Switch;
import de.japkit.test.members.common.annotations.AnnotationsTemplate;
import de.japkit.test.members.common.body.BodyTemplate;
import de.japkit.test.members.common.condition.ConditionTemplate;
import de.japkit.test.members.common.modifiers.ModifiersTemplate;
import de.japkit.test.members.common.name.MemberNameTemplate;
import de.japkit.test.members.common.source.SourceTemplate;
import de.japkit.test.members.common.type.TypeTemplate;
import de.japkit.test.members.method.MethodTemplate;

/**
 * This template shows how to generate fields and optionally getters and setters
 * for them.
 * <ul>
 * <li>For more details on how to generate fields conditionally, see
 * {@link ConditionTemplate}.
 * <li>For more details on how to set the src and how to generate multiple
 * fields from one field template, see {@link SourceTemplate}.
 * <li>For more details on how to set the modifiers of the field, see
 * {@link ModifiersTemplate}.
 * <li>For more details on how to set the annotations of the field, see
 * {@link AnnotationsTemplate}.
 * <li>For more details on how to set the type of the field, see
 * {@link TypeTemplate}.
 * <li>For more details on how to set the name of the field, see
 * {@link MemberNameTemplate}.
 * <li>For more details on how to generate the initializer code of the field,
 * see {@link BodyTemplate}.
 * </ul>
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class FieldTemplate {

	/**
	 * A field with fix name and type and with public getters and setters.
	 * <p>
	 * While getters and setters could be generated as methods (see
	 * {@link MethodTemplate}), they are so common that japkit provides some
	 * more convenience for it.
	 * <p>
	 * The field is initialized with the value "foobar".
	 */
	@Field(
		getter = @Getter(commentExpr = "the value of fixedField"),
		setter = @Setter(commentExpr = "the new value for fixedField"),
		initCode = "\"foobar\"")
	private String fixedField;

	/**
	 * A field for every field in the annotated class {@link FieldExample}.
	 * <p>
	 * The setters are fluent style and return this for chaining.
	 * <p>
	 * For fields with a {@link NotNull} annotation, a null-check is added to
	 * the setter by calling the {@link CodeFragment} {@link notNullCheck}. For
	 * {@link FieldExample#someString} this will result in
	 * 
	 * <pre>
	 * if (someString == null) {
	 * 	throw new IllegalArgumentException("someString must not be null.");
	 * }
	 * this.someString = someString;
	 * </pre>
	 * <p>
	 * For fields of mutable types, the {@link setterDefensiveCopy} is called to
	 * make a defensive copy in the setter. The code generated by that fragment
	 * "surrounds" the right hand side of the assignment in the setter. For
	 * example, for the field {@link FieldExample#someStringList} this will
	 * result in
	 * 
	 * <pre>
	 * this.someStringList = new ArrayList<>(someStringList);
	 * 
	 * </pre>
	 */
	@Field(
		srcFun = fields.class,
		getter = @Getter(commentExpr = "the value of #{name}"),
		setter = @Setter(
			commentExpr = "the new value for #{name}",
			chain = true,
			fluent = true,
			beforeFragments = "notNullCheck",
			surroundAssignmentExprFragments = "setterDefensiveCopy"),
		genElementIsSrcForDependentRules = false)
	private SrcType $name$;

	/**
	 * This will generate a statement that checks for null, if the given source
	 * element has the {@link NotNull} annotation.
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
	@CodeFragment(condFun = hasNotNull.class)
	class notNullCheck {
	}

	/**
	 * Generates a code to create a defensive copy if a mutable type is used.
	 * <p>
	 * Here, only List is supported, but more cases could be added (Set, Map,
	 * Date, ...).
	 */
	@Switch
	class setterDefensiveCopy {

		@isList
		@CodeFragment(imports = ArrayList.class, code = "new ArrayList<>(#{surrounded})")
		String copyList;

		@DefaultCase
		@CodeFragment(code = "#{surrounded}")
		String deflt;

	}

	/**
	 * To show some more complex initializer code, a constant field is generated
	 * here that has the array of all field names as value.
	 * <ul>
	 * <li>The initIterator tells to iterate over the fields of the annotated
	 * class.
	 * <li>The initBeforeIteratorCode is the code to be generated before the
	 * iteration starts.
	 * <li>The initAfterIteratorCode is the code to be generated after the
	 * iteration ends.
	 * <li>The initCode is the code to be generated for each iteration. Here, it
	 * is the name of the field from the annotated class in double quotes.
	 * <ul>
	 * 
	 * @japkit.initBeforeIteratorCode new String[] {
	 * @japkit.initCode "#{name}"
	 * @japkit.initSeparator ,
	 * @japkit.initAfterIteratorCode }
	 */
	@Field(initIterator = "#{fields()}")
	public static final String[] FIELD_NAMES = new String[0];

	/**
	 * A function to get the fields of a {@link TypeElement}.
	 */
	@Function(expr = "#{enclosedElements}", filter = "#{kind == 'FIELD'}")
	class fields {
	}

	/**
	 * A function that returns true if the given element has a {@link NotNull}
	 * annotation.
	 */
	@Matcher(annotations = NotNull.class)
	class hasNotNull {
	}

	/**
	 * A function that returns true if the given element's type is List.
	 * <p>
	 * The function is declared as an annotation to use it within a
	 * {@link Switch}.
	 */
	@Documented
	@Matcher(type = List.class)
	public @interface isList {
	}

}
