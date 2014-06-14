package de.stefanocke.japkit.roo.japkit;

import javax.lang.model.element.Modifier;
import javax.persistence.Entity;

import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.GenerateClass;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Members;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.AnnotatedClass;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.roo.japkit.JapkitEntity.SuperclassSelector;

@GenerateClass(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifier = Modifier.PUBLIC,
		annotationMappings = { @AnnotationMapping(targetAnnotation = Entity.class) }, superclass = SuperclassSelector.class,
		members = { @Members(IdAndVersion.class), 
				@Members,
				@Members(ToString.class),
				@Members(activation = @Matcher(condition = "#{currentAnnotation.activeRecord}"), value = ActiveRecordMembers.class) })
@Properties(sourceClass = AnnotatedClass.class, fromFields = true, annotationMappings = @AnnotationMapping(copyAnnotationsFromPackages = {
		"javax.persistence", "javax.validation.constraints", "org.springframework.format.annotation" })
/* ,templates = PropertyTemplateTest.class */)
@Var(name = "superclass", expr = "#{currentAnnotatedClass.superclass}", requiredTriggerAnnotation=JapkitEntity.class)
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
