package de.stefanocke.japkit.roo.japkit;

import javax.lang.model.element.Modifier;
import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Constructor;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Param;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.AnnotatedClass;
import de.stefanocke.japkit.metaannotations.classselectors.SrcElementType;


@Properties(sourceClass = AnnotatedClass.class, fromFields = true, fieldModifiers = { Modifier.PRIVATE /**, Modifier.FINAL*/ },
generateSetters=false, annotationMappings = @AnnotationMapping(copyAnnotationsFromPackages = { "javax.persistence",
		"javax.validation.constraints", "org.springframework.format.annotation" }))
@Template(vars=@Var(
		name = "validationFragment",
		code = 
				@CodeFragment(
						activation = @Matcher(srcAnnotations = NotNull.class),
						expr = "if(#{element.simpleName}==null){\n" +
								"  throw new IllegalArgumentException(\"#{element.simpleName} must not be null.\");\n" +
								"}\n")))
public class ValueObjectTemplate {
	@Constructor(bodyExpr="//Some ctor code")
	private ValueObjectTemplate (){};
	
	@Constructor(bodyIterator = "#{properties}", 
			bodyExpr = "#{validationFragment.code()}" +
			"this.#{element.simpleName} = #{element.simpleName};\n")
	public ValueObjectTemplate(@Param(iterator = "#{properties}", nameExpr = "#{element.simpleName}", annotationMappings = @AnnotationMapping(
			copyAnnotationsFromPackages = { "javax.validation.constraints" })) SrcElementType property) {
	};
	
}
