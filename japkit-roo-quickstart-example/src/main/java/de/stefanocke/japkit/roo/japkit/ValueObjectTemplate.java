package de.stefanocke.japkit.roo.japkit;

import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Constructor;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.InnerClass;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.metaannotations.classselectors.SrcElementType;



@Template(vars=@Var(
		name = "validationFragment",
		code = 
				@CodeFragment(
						activation = @Matcher(srcAnnotations = NotNull.class),
						expr = "if(#{element.simpleName}==null){\n" +
								"  throw new IllegalArgumentException(\"#{element.simpleName} must not be null.\");\n" +
								"}\n")))
public abstract class ValueObjectTemplate {
	
	@InnerClass
	@ClassSelector(kind=ClassSelectorKind.GEN_INNER_CLASS_NAME, expr="Builder") //TODO!
	public static abstract class Builder{
		@Field(iterator = "#{properties}", nameExpr = "#{element.simpleName}", annotationMappings = @AnnotationMapping(
				copyAnnotationsFromPackages = { "javax.persistence", "javax.validation.constraints",
						"org.springframework.format.annotation" }), generateGetter = true, generateSetter = true)
		private SrcElementType field;
		
		
		@ClassSelector(kind=ClassSelectorKind.EXPR, expr="#{currentGenClass.enclosingElement.asType()}")
		abstract static class EnclosingClass{}
		
		@Method(bodyExpr="return new #{currentGenClass.enclosingElement.simpleName}(this);") 
		public abstract EnclosingClass build();
	}
	
	@Field(iterator="#{properties}", nameExpr="#{element.simpleName}",
			annotationMappings = @AnnotationMapping(copyAnnotationsFromPackages = { "javax.persistence",
					"javax.validation.constraints", "org.springframework.format.annotation" }), generateGetter = true)
	private SrcElementType field;
	
	@Constructor(bodyExpr="//Some ctor code")
	private ValueObjectTemplate (){};
	
	
	@Constructor(bodyIterator = "#{properties}", 
			bodyExpr = "#{validationFragment.code()}" +
			"this.#{element.simpleName} = builder.#{element.simpleName};\n")
	@ParamNames("builder")
	private ValueObjectTemplate(Builder builder) {
	}
	
	
	
	
}
