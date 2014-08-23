package de.stefanocke.japkit.roo.japkit;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.AnnotatedClass;

@Target(ElementType.TYPE)
@Clazz(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifiers = { Modifier.PUBLIC, Modifier.FINAL }, templates = {
		@TemplateCall(ValueObjectTemplate.class), @TemplateCall(ToString.class) })
@Var(name = "properties", propertyFilter = @Properties(sourceClass = AnnotatedClass.class, fromFields = true))
public @interface ValueObject {
	boolean shadow() default false;

	boolean customBehavior() default false;

}
