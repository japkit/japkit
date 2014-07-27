package de.stefanocke.japkit.roo.japkit;

import java.util.Date;

import javax.lang.model.element.Modifier;
import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.Case;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Constructor;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.InnerClass;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Members;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.metaannotations.classselectors.SrcElementType;



@Template(vars = {
		@Var(name = "validationFragment", code = @CodeFragment(activation = @Matcher(annotations = NotNull.class),
				expr = "if(#{src.simpleName}==null){\n"
						+ "  throw new IllegalArgumentException(\"#{src.simpleName} must not be null.\");\n" + "}\n")),
		@Var(name = "defensiveCopyFragment", code = @CodeFragment(imports=Date.class, cases = { @Case(matcher = @Matcher(type = Date.class),
				expr = "new Date(#{surrounded}.getTime())")}))
//		,
//		@Var(name = "tryFinallyTest", code = @CodeFragment(expr="try {\n" +
//				"#{surrounded}" +
//				"} finally {\n" +
//				"}\n"))
})


public abstract class ValueObjectTemplate {
	
	@InnerClass(members=@Members(Builder.class))
	@Field(iterator = "#{properties}", modifiers=Modifier.PRIVATE, annotationMappings = @AnnotationMapping(
			copyAnnotationsFromPackages = { "javax.persistence", "javax.validation.constraints",
					"org.springframework.format.annotation" }), getter=@Getter(fluent=true), setter=@Setter(fluent=true, chain=true), commentFromSrc = true)
	@ClassSelector(kind=ClassSelectorKind.GEN_INNER_CLASS_NAME, expr="Builder") //TODO!
	public static abstract class Builder{
		
		@ClassSelector(kind=ClassSelectorKind.EXPR, expr="#{currentGenClass.enclosingElement.asType()}")
		abstract static class EnclosingClass{}
		
		@Method(bodyExpr="return new #{currentGenClass.enclosingElement.simpleName}(this);") 
		public abstract EnclosingClass build();
	}
	
	@Field(iterator = "#{properties}", 
			annotationMappings = @AnnotationMapping(copyAnnotationsFromPackages = { "javax.persistence", "javax.validation.constraints",
					"org.springframework.format.annotation" }), commentFromSrc = true, getter = @Getter(
					fluent=true,
					surroundReturnExprFragments = "defensiveCopyFragment",
					commentExpr = "Getter for #{src.simpleName}. \n@returns #{src.simpleName}\n"))
	private SrcElementType srcElementName;

	@Constructor(bodyExpr="//Some ctor code")
	private ValueObjectTemplate (){};
	
	
	@Constructor(
			vars={@Var(name = "rhs", code=@CodeFragment(expr="builder.#{src.simpleName}", surroundingFragments="defensiveCopyFragment")),
				  @Var(name = "assignment", code=@CodeFragment(expr="this.#{src.simpleName} = #{rhs.code()};\n", beforeFragments="validationFragment"))}, 
			bodyIterator = "#{properties}", 	
			bodyExpr = "#{assignment.code()}")
	@ParamNames("builder")
	private ValueObjectTemplate(Builder builder) {
	}
	
}
