package de.stefanocke.japkit.roo.japkit;

import javax.lang.model.element.Modifier;
import javax.persistence.Entity;

import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.roo.japkit.JapkitEntity.SuperclassSelector;

@Trigger(vars=@Var(name = "superclass", expr = "#{annotatedClass.superclass}", requiredTriggerAnnotation = JapkitEntity.class))
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

	// TODO: Es sollte möglich sein, direkt am Selektor anzugeben, dass das
	// Ergebnis gemäß einer GenClass-Annotation aufgelöst werden soll.
	// dabei kann man dann auch noch die in frage kommenden Trigger-Annotationen
	// angeben.
	@ClassSelector(kind = ClassSelectorKind.EXPR, expr = "#{superclass}")
	static class SuperclassSelector {
	};

}
