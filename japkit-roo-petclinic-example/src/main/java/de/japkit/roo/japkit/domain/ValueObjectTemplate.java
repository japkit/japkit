package de.japkit.roo.japkit.domain;

import static de.japkit.roo.japkit.domain.AnnotationPackages.JPA;
import static de.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;

import java.util.Date;

import javax.lang.model.element.Modifier;
import javax.persistence.Embeddable;
import javax.validation.constraints.NotNull;

import de.japkit.annotations.Order;
import de.japkit.annotations.ParamNames;
import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.Case;
import de.japkit.metaannotations.CodeFragment;
import de.japkit.metaannotations.Constructor;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Getter;
import de.japkit.metaannotations.InnerClass;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Setter;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Var;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.japkit.metaannotations.classselectors.GeneratedClass;
import de.japkit.metaannotations.classselectors.SrcType;

@RuntimeMetadata
@Template(vars=@Var(name="properties", expr="#{src.declaredFields}"))
@Embeddable
public abstract class ValueObjectTemplate {
	@Matcher(annotations = NotNull.class)
	class mandatory{};
	
	/**
	 * @japkit.code <pre>
	 * <code>
	 * if(#{param}==null){
	 * 	throw new IllegalArgumentException("#{param} must not be null.");
	 * }
	 * </code>
	 * </pre>
	 */
	@CodeFragment(condFun = mandatory.class)
	static class validationFragment{}
	
	@CodeFragment(imports = Date.class,
			cases = { @Case(cond = "isDate", value = "new Date(#{surrounded}.getTime())") })
	static class defensiveCopyFragment {
	}

	@Function(expr="#{src.declaredFields}")
	class props{}
	
	@Order(1)
	@InnerClass(fields = @Field(srcFun = {props.class}, modifiers = Modifier.PRIVATE,
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
