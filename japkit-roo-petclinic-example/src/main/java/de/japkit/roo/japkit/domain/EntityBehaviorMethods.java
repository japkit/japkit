package de.japkit.roo.japkit.domain;

import static de.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;

import javax.lang.model.element.Modifier;
import javax.persistence.Id;
import javax.persistence.Version;

import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.CodeFragment;
import de.japkit.metaannotations.Constructor;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Param;
import de.japkit.metaannotations.Properties;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Var;
import de.japkit.metaannotations.classselectors.GeneratedClass;
import de.japkit.metaannotations.classselectors.SrcType;

@Template(vars = {@Var(name = "superconstructors",
		expr = "#{genClass.superclass.asElement.declaredConstructors}"),
		@Var(name="entityName", expr="#{genClass.simpleName}")})
public abstract class EntityBehaviorMethods {
	
	@CodeFragment(iterator = "#{src}", code = "#{src.setter.simpleName}(#{src.simpleName});", indentAfterLinebreak=false)
	static class assignments{}
	/**
	 * Default constructor for JPA. //TODO: Make protected as soon as controllers support that.
	 */
	@Constructor()
	public EntityBehaviorMethods() {
	};

	//	/**
	//	 * @japkit.bodyCode <pre>
	//	 * <code>
	//	 * #{super.code()}#{assignments.code()}
	//	 * </code>
	//	 * </pre>
	//	 */
	//	@Constructor(src="superconstructors", 
	//			srcFilter="#{!src.parameters.isEmpty() || superconstructors.size()==1}",
	//			vars = { 
	//				
	//				@Var(name = "super", code = @CodeFragment(beforeIteratorCode="super(", afterIteratorCode=");", iterator="#{src.parameters}" , separator = ", ", linebreak=false, code="#{src.simpleName}") ),
	//				@Var(name = "assignments", code = @CodeFragment(iterator = "#{genClass.declaredFields}", code = "set#{src.simpleName.toFirstUpper}(#{src.simpleName});"))
	//			} 
	//			
	//			)

	@Matcher(src = "#{genClass}", modifiersNot = Modifier.ABSTRACT)
	class genClassNotAbstract{};
	
	/**
	 */
	@Constructor(condFun = genClassNotAbstract.class,
		vars = @Var(name="cmdPropertiesWhiteList", expr="#{createCommandProperties}"),
		bodyCode="#{assignments(commandProperties())}"	
	)
	public EntityBehaviorMethods(
		@Param(src = "commandProperties", 
			annotations = @Annotation(copyAnnotationsFromPackages={JSR303, SPRING_FORMAT})) 
		SrcType $srcElementName$) {

	}

	@Method(condFun = genClassNotAbstract.class, 			
			vars = @Var(name="cmdPropertiesWhiteList", expr="#{updateCommandProperties}"),
			bodyCode="#{assignments(commandProperties())}")
	public void update$entityName$(
			@Param(src = "commandProperties", 
				annotations = @Annotation(copyAnnotationsFromPackages={JSR303, SPRING_FORMAT})) 
			SrcType $srcElementName$){}
	
	@Properties(sourceClass = GeneratedClass.class, 
			includeNamesExpr = "cmdPropertiesWhiteList",
			includeRules = @Matcher(condition="#{cmdPropertiesWhiteList.isEmpty()}"),
			excludeRules={@Matcher(annotations=Id.class), @Matcher(annotations=Version.class)} )
	class commandProperties{}

}
