package de.stefanocke.japkit.roo.japkit.domain;

import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.JPA;
import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;

import javax.lang.model.element.Modifier;
import javax.persistence.Entity;

import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.roo.japkit.Layers;
import de.stefanocke.japkit.roo.japkit.domain.JapkitEntity.SuperclassSelector;

@Trigger(layer=Layers.ENTITIES)
@Clazz(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifiers = Modifier.PUBLIC, modifiersFromSrc=true, annotations = { @Annotation(
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
