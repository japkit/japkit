package de.japkit.roo.japkit.domain;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.Trigger;
import de.japkit.roo.japkit.Layers;

@Trigger(layer = Layers.VALUE_OBJECTS)
@Target(ElementType.TYPE)
@Clazz(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifiers = { Modifier.PUBLIC, Modifier.FINAL }, templates = {
		@TemplateCall(ValueObjectTemplate.class), @TemplateCall(ToString.class) })
public @interface ValueObject {
	boolean shadow() default false;

	boolean customBehavior() default false;

}
