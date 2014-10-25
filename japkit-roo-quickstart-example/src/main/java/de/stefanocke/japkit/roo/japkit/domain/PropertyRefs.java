package de.stefanocke.japkit.roo.japkit.domain;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.ENTITIES)
@Clazz(nameSuffixToRemove = "Def",
		nameSuffixToAppend = "Properties",
		modifiers = Modifier.PUBLIC,
		templates = @TemplateCall(PropertyRefsTemplate.class))
public @interface PropertyRefs {
	boolean shadow() default false;
}
