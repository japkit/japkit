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
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.roo.japkit.domain.JapkitEntity.SuperclassSelector;

@Trigger
@Clazz(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifiers = Modifier.PUBLIC, annotations = { @Annotation(
		targetAnnotation = Entity.class) }, superclass = SuperclassSelector.class, templates = { @TemplateCall(IdAndVersion.class),
		@TemplateCall(ToString.class),
		@TemplateCall(activation = @Matcher(condition = "#{triggerAnnotation.activeRecord}"), value = ActiveRecordMembers.class) },
		fields = @Field(src = "#{src.declaredFields}", getter = @Getter, setter = @Setter, annotations = @Annotation(
				copyAnnotationsFromPackages = { "javax.persistence", "javax.validation.constraints",
						"org.springframework.format.annotation" })))

public @interface JapkitEntity {
	// Modifier[] modifier() default {};

	boolean shadow() default false;

	boolean activeRecord() default false;

	boolean customBehavior() default false;

	@ClassSelector(kind = ClassSelectorKind.EXPR, expr = "#{annotatedClass.superclass}", requiredTriggerAnnotation=JapkitEntity.class)
	static class SuperclassSelector {
	};

}
