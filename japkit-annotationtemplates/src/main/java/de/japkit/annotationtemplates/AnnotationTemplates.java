package de.japkit.annotationtemplates;

import java.lang.annotation.Annotation;

import de.japkit.metaannotations.Trigger;

@Trigger(layer=-2, template=AnnotationTemplatesTemplate.class)
public @interface AnnotationTemplates {
	boolean shadow() default false;
	
	Class<? extends Annotation>[] targetAnnotations() default {};
}
