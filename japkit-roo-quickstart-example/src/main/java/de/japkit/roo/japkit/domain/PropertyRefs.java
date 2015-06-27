package de.japkit.roo.japkit.domain;

import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.Trigger;
import de.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.ENTITIES)
@Clazz(nameSuffixToRemove = "Def",
		nameSuffixToAppend = "Properties",
		modifiers = Modifier.PUBLIC,
		templates = @TemplateCall(PropertyRefsTemplate.class))
public @interface PropertyRefs {
	boolean shadow() default false;
}
