package de.stefanocke.japkit.roo.japkit.domain;

import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;

import javax.lang.model.element.Modifier;
import javax.persistence.Id;
import javax.persistence.Version;

import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Constructor;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Param;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;
import de.stefanocke.japkit.metaannotations.classselectors.SrcType;

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

	/**
	 */
	@Constructor(activation = @Matcher(src = "#{genClass}", modifiersNot = Modifier.ABSTRACT),
		vars = @Var(name="cmdPropertiesWhiteList", expr="#{createCommandProperties}"),
		bodyCode="#{assignments(commandProperties())}"	
	)
	public EntityBehaviorMethods(
		@Param(src = "commandProperties", 
			annotations = @Annotation(copyAnnotationsFromPackages={JSR303, SPRING_FORMAT})) 
		SrcType $srcElementName$) {

	}

	@Method(activation =  @Matcher(src = "#{genClass}", modifiersNot = Modifier.ABSTRACT), 			
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
