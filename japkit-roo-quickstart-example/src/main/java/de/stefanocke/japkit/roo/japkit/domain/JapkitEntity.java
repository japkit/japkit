package de.stefanocke.japkit.roo.japkit.domain;

import javax.lang.model.element.Modifier;
import javax.persistence.Entity;

import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Matcher;
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
		@TemplateCall(activation = @Matcher(condition = "#{triggerAnnotation.activeRecord}"), value = ActiveRecordMembers.class),
		@TemplateCall(EntityBehaviorMethods.class)},
		fields = {@Field(src = "#{src.declaredFields}", modifiers=Modifier.PRIVATE, getter = @Getter, setter = @Setter(modifiers=Modifier.PROTECTED), annotations = @Annotation(
				copyAnnotationsFromPackages = { "javax.persistence", "javax.validation.constraints",
						"org.springframework.format.annotation" } ))	
				})

public @interface JapkitEntity {
	// Modifier[] modifier() default {};

	boolean shadow() default false;

	boolean activeRecord() default false;

	boolean customBehavior() default false;

	@ClassSelector(expr = "#{annotatedClass.superclass}", requiredTriggerAnnotation=JapkitEntity.class)
	static class SuperclassSelector {
	};
	
	Class<?>[] createCommandProperties() default {};
	
	Class<?>[] updateCommandProperties() default {};

}
