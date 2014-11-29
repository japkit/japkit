package de.stefanocke.japkit.roo.japkit.application;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.APPLICATION)
@Clazz(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifiers = Modifier.PUBLIC, 
	templates=@TemplateCall(ApplicationServiceTemplate.class))
public @interface ApplicationService {
	
	boolean shadow() default false;
	
	Class<?>[] aggregateRoots() default {};
	
	Class<?>[] customBehaviorFor() default {};
}
