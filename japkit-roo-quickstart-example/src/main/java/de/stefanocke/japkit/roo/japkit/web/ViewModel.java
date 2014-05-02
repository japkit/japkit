package de.stefanocke.japkit.roo.japkit.web;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.GenerateClass;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.classselectors.AnnotatedClass;

@GenerateClass(classSuffixToRemove = "ViewModelDef", classSuffixToAppend = "ViewModel", modifier= Modifier.ABSTRACT)
@Properties(sourceClass = FormBackingObject.class, overrides = AnnotatedClass.class, generateGetters = true, generateSetters = false,
		annotationMappings = @AnnotationMapping(copyAnnotationsFromPackages = "*"))
public @interface ViewModel {
	boolean shadow() default false;

	Class<?> formBackingObject();
}
