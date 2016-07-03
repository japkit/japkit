package de.japkit.roo.japkit.meta;

import java.lang.annotation.Annotation;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.InnerClass;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.Trigger;

@Trigger(layer=-2)
@Clazz(modifiers=Modifier.PUBLIC, innerClasses=
@InnerClass(src="#{triggerAnnotation.targetAnnotations}", modifiers=Modifier.PUBLIC, kind=ElementKind.ANNOTATION_TYPE, 
	nameExpr="#{src.asElement().simpleName}_",
	templates={@TemplateCall(AnnotationTemplateAVMembers.class), @TemplateCall(AnnotationTemplateMembers.class)}))
public @interface AnnotationTemplates {
	boolean shadow() default false;
	
	Class<? extends Annotation>[] targetAnnotations() default {};
}
