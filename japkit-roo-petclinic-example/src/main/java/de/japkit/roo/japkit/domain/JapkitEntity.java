package de.japkit.roo.japkit.domain;

import static de.japkit.roo.japkit.domain.AnnotationPackages.JPA;
import static de.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;

import javax.lang.model.element.Modifier;
import javax.persistence.Entity;

import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Getter;
import de.japkit.metaannotations.Setter;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.Trigger;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.roo.japkit.Layers;
import de.japkit.roo.japkit.domain.JapkitEntity.SuperclassSelector;

@Trigger(layer=Layers.ENTITIES)
@Clazz(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifiers = Modifier.PUBLIC, modifiersFromSrc=true, 
		customBehaviorCond="#{customBehavior}",
		annotations = { @Annotation(
		targetAnnotation = Entity.class) }, superclass = SuperclassSelector.class, templates = { @TemplateCall(IdAndVersion.class), 
		@TemplateCall(PropertyRefsTemplate.class),
		@TemplateCall(ToString.class),
		@TemplateCall(EntityBehaviorMethods.class)},
		fields = {@Field(src = "#{src.declaredFields}", modifiers=Modifier.PRIVATE, getter = @Getter, setter = @Setter(modifiers=Modifier.PROTECTED), annotations = @Annotation(
				copyAnnotationsFromPackages = { JPA, JSR303, SPRING_FORMAT } ))	
				})

public @interface JapkitEntity {
	// Modifier[] modifier() default {};

	boolean shadow() default false;

	boolean customBehavior() default false;

	@ClassSelector(expr = "#{annotatedClass.superclass}", requiredTriggerAnnotation=JapkitEntity.class)
	static class SuperclassSelector {
	};
	
	Class<?>[] createCommandProperties() default {};
	
	Class<?>[] updateCommandProperties() default {};

}
