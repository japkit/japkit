package de.stefanocke.japkit.roo.japkit.domain;

import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.JPA;
import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;

import java.util.Date;

import javax.lang.model.element.Modifier;
import javax.persistence.Embeddable;
import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.annotations.Order;
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
@Template(vars=@Var(name="properties", expr="#{src.declaredFields}"))
@Embeddable
public abstract class ValueObjectTemplate {
	/**
	 * @japkit.code <pre>
	 * <code>
	 * if(#{param}==null){
	 * 	throw new IllegalArgumentException("#{param} must not be null.");
	 * }
	 * </code>
	 * </pre>
	 */
	@CodeFragment(activation = @Matcher(annotations = NotNull.class))
	static class validationFragment{}
	
	@CodeFragment(imports = Date.class,
			cases = { @Case(matcher = @Matcher(type = Date.class),
					expr = "new Date(#{surrounded}.getTime())") })
	static class defensiveCopyFragment {
	}

	@Order(1)
	@InnerClass(fields = @Field(src = "#{properties}", modifiers = Modifier.PRIVATE,
			annotations = @Annotation(copyAnnotationsFromPackages = { JPA, JSR303, SPRING_FORMAT }), 
				getter = @Getter(/*fluent = true*/), setter = @Setter(/*fluent = true,*/
					chain = true), commentFromSrc = true))
	@ClassSelector(kind = ClassSelectorKind.INNER_CLASS_NAME, enclosing = GeneratedClass.class)
	public static abstract class Builder {

		@ClassSelector(expr = "#{genClass.enclosingElement.asType()}")
		abstract static class EnclosingClass {
		}

		@Method(bodyCode = "return new #{genElement.returnType.code}(this);")
		public abstract EnclosingClass build();
	}

	@Order(2)
	@Field(src = "#{properties}", annotations = @Annotation(copyAnnotationsFromPackages = { JPA, JSR303, SPRING_FORMAT }), 
		commentFromSrc = true, getter = @Getter(
			/*fluent = true,*/ surroundReturnExprFragments = "defensiveCopyFragment"))
	private SrcType $srcElementName$;

	@Order(3)
	@Constructor(bodyCode = "//Some ctor code")
	private ValueObjectTemplate() {
	};
	
	@CodeFragment(code = "#{src}", surroundingFragments = "defensiveCopyFragment")
	static class rhs{}
	
	@CodeFragment(code = "/**after*/")
	static class after{};
	
	@CodeFragment(vars = @Var(name="param", expr ="builder.#{src.simpleName}"),
			code = "this.#{src.simpleName} = #{rhs(param)};",	beforeFragments = "validationFragment")
	static class assignment{}
	
	@Order(4)
	@Constructor(bodyIterator = "properties", bodyCode = "#{assignment()}")
	@ParamNames("builder")
	private ValueObjectTemplate(Builder builder) {
	}

}
