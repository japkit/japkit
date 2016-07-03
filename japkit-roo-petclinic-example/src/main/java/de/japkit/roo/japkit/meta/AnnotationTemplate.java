package de.japkit.roo.japkit.meta;

import java.lang.annotation.Annotation;

public @interface AnnotationTemplate {
	Class<? extends Annotation> targetAnnotations();
}
