package de.japkit.test.members.common.source;

import javax.lang.model.element.Element;
import javax.lang.model.element.TypeElement;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.functions.SrcType;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.InnerClass;
import de.japkit.metaannotations.Template;

/**
 * When generating members, the src (source) variable can be set by evaluating
 * an expression (src) or calling a function (srcFun). If the src variable is
 * set to a collection value, a member for each field in that collection is
 * generated.
 * <p>
 * The template mainly generates fields, but the same applies also to methods,
 * constructors and inner classes.
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class SourceTemplate {

	/**
	 * If no src is set, the src variable is the same as the one of the
	 * surrounding template. Since this is the {@link Clazz} template here, the
	 * src is the {@link TypeElement} for the class annotated with the trigger
	 * annotation.
	 * <p>
	 * So, the resulting field name is "sourceExample", since the src is the
	 * {@link TypeElement} for the annotated class {@link SourceExample}, and
	 * its {@link TypeElement#getSimpleName()} is "SourceExample".
	 */
	@Field(nameExpr = "#{src.simpleName.toFirstLower}")
	String originalSourceIsTheAnnotatedClass;

	/**
	 * Here, the src is set to the list of fields of the {@link TypeElement} for
	 * the annotated class {@link SourceExample}. For a src of a collection
	 * type, the member template is applied for every element. Thus, there is a
	 * field generated for every field in this list. The resulting fields are
	 * "srcField1Copy" and "srcField2Copy".
	 * <p>
	 * The new src hides the original one, which was the {@link TypeElement} for
	 * the annotated class {@link SourceExample}. If generating the member is
	 * done, the original src is restored again. In other words, each member is
	 * generated within a new scope with its own value for src and potentially
	 * other variables.
	 */
	@Field(src = "#{src.enclosedElements.stream().filter(e -> e.kind == 'FIELD').toList()}", nameExpr = "#{src.simpleName}Copy1")
	SrcType srcIsSetToTheListOfFields;

	/**
	 * Since filtering is quite common for a src collection, the filter
	 * condition can also be provided as srcFilter.
	 */
	@Field(src = "#{src.enclosedElements}", srcFilter = "#{src.kind == 'FIELD'}", nameExpr = "#{src.simpleName}Copy2")
	SrcType srcIsSetToTheListOfFieldsFilter;

	/**
	 * The src variable is always implicit in expressions, so it can be omitted.
	 */
	@Field(src = "#{enclosedElements}", srcFilter = "#{kind == 'FIELD'}", nameExpr = "#{simpleName}Copy3")
	SrcType srcIsSetToTheListOfFieldsFilterSrcIsImplicit;

	/**
	 * A function to get the fields of a {@link TypeElement}.
	 */
	@Function(expr = "#{enclosedElements}", filterFun = isField.class)
	class fields {
	}

	/**
	 * A function to determine whether an {@link Element} is a field.
	 */
	@Function(expr = "#{kind == 'FIELD'}")
	class isField {
	}

	/**
	 * Also, a function can be called to determine the source.
	 */
	@Field(srcFun = fields.class, nameExpr = "#{simpleName}Copy4")
	SrcType srcIsSetToTheListOfFieldsWithFunction;

	/**
	 * Also, a function can be called to filter the source.
	 */
	@Field(src = "#{enclosedElements}", srcFilterFun = isField.class, nameExpr = "#{simpleName}Copy5")
	SrcType srcIsSetToTheListOfFieldsWithFilterFunction;

	/**
	 * If multiple elements shall be generated for the same src, they can be
	 * grouped by a template. Note that this will not generate an inner class
	 * inadvertently, since this would require an {@link InnerClass} annotation.
	 * <p>
	 * Here, we generate a method and a field for every field in the annotated
	 * class.
	 * <p>
	 * Templates can also be nested.
	 */
	@Template(srcFun = fields.class)
	class FieldAndMethod {
		/**
		 * A field for every element in the src collection of
		 * {@link FieldAndMethod} template.
		 */
		SrcType $simpleName$Copy6;

		/**
		 * A method for every element in the src collection of
		 * {@link FieldAndMethod} template.
		 */
		void set$simpleName$(SrcType $simpleName$) {
		}
	}
}
