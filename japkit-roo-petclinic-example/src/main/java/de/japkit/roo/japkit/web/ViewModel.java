package de.japkit.roo.japkit.web;

import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Getter;
import de.japkit.metaannotations.Trigger;
import de.japkit.metaannotations.classselectors.AnnotatedClass;
import de.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.VIEW_MODELS)
@Clazz(nameSuffixToRemove = "ViewModelDef",
		nameSuffixToAppend = "ViewModel",
		modifiers = Modifier.ABSTRACT,
		fields = @Field(src = "#{formBackingObject.asElement.properties}",
				manualOverrides = AnnotatedClass.class,
				annotations = @Annotation(src = "#{src.field}",
						copyAnnotationsFromPackages = "*"),
				getter = @Getter))
public @interface ViewModel {
	
	boolean shadow() default false;

	Class<?> formBackingObject();
}
