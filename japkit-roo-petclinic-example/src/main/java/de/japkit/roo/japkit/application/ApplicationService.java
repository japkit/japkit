package de.japkit.roo.japkit.application;

import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.Trigger;
import de.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.APPLICATION)
@Clazz(nameSuffixToRemove = "Def", nameSuffixToAppend = "", modifiers = Modifier.PUBLIC, 
	templates=@TemplateCall(ApplicationServiceTemplate.class))
public @interface ApplicationService {
	
	boolean shadow() default false;
	
	Class<?>[] aggregateRoots() default {};
	
	Class<?>[] customBehaviorFor() default {};
}
