package de.stefanocke.japkit.roo.japkit;

import java.util.Date;

import javax.lang.model.element.Modifier;
import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.annotations.ParamNames;
import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Case;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Constructor;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.InnerClass;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;
import de.stefanocke.japkit.metaannotations.classselectors.SrcType;

@RuntimeMetadata
@Template(vars = {
		@Var(name = "validationFragment", code = @CodeFragment(activation = @Matcher(annotations = NotNull.class),
				code = "if(#{src.simpleName}==null){\n"
						+ "  throw new IllegalArgumentException(\"#{src.simpleName} must not be null.\");\n" + "}")),
		@Var(name = "defensiveCopyFragment", code = @CodeFragment(imports = Date.class, cases = { @Case(matcher = @Matcher(
				type = Date.class), expr = "new Date(#{surrounded}.getTime())") }, linebreak = false))
// ,
// @Var(name = "tryFinallyTest", code = @CodeFragment(expr="try {\n" +
// "#{surrounded}" +
// "} finally {\n" +
// "}\n"))
		})
public abstract class ValueObjectTemplate {

	@InnerClass(fields = @Field(src = "#{properties}", modifiers = Modifier.PRIVATE,
			annotations = @Annotation(copyAnnotationsFromPackages = { "javax.persistence", "javax.validation.constraints",
					"org.springframework.format.annotation" }), getter = @Getter(fluent = true), setter = @Setter(fluent = true,
					chain = true), commentFromSrc = true))
	@ClassSelector(kind = ClassSelectorKind.INNER_CLASS_NAME, enclosing = GeneratedClass.class)
	public static abstract class Builder {

		@ClassSelector(kind = ClassSelectorKind.EXPR, expr = "#{genClass.enclosingElement.asType()}")
		abstract static class EnclosingClass {
		}

		@Method(bodyCode = "return new #{genElement.returnType.code}(this);")
		public abstract EnclosingClass build();
	}

	@Field(src = "#{properties}", annotations = @Annotation(copyAnnotationsFromPackages = { "javax.persistence",
			"javax.validation.constraints", "org.springframework.format.annotation" }), commentFromSrc = true, getter = @Getter(
			fluent = true, surroundReturnExprFragments = "defensiveCopyFragment",
			commentExpr = "Getter for #{src.simpleName}. \n@returns #{src.simpleName}\n"))
	private SrcType $srcElementName$;

	@Constructor(bodyCode = "//Some ctor code")
	private ValueObjectTemplate() {
	};

	@Constructor(vars = {
			@Var(name = "rhs", code = @CodeFragment(code = "builder.#{src.simpleName}", surroundingFragments = "defensiveCopyFragment",
					linebreak = false)),
			@Var(name = "assignment", code = @CodeFragment(code = "this.#{src.simpleName} = #{rhs.code()};",
					beforeFragments = "validationFragment")) }, bodyIterator = "properties", bodyCode = "assignment")
	@ParamNames("builder")
	private ValueObjectTemplate(Builder builder) {
	}

}
