package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.GenerateClass;
import de.stefanocke.japkit.metaannotations.ResourceLocation;
import de.stefanocke.japkit.metaannotations.ResourceTemplate;
import de.stefanocke.japkit.metaannotations.TypeQuery;

@Var.List({
		@Var(name = "controllers", triggerAV = "controllers", typeQuery = @TypeQuery(annotation = JapkitWebScaffold.class, shadow = true),
				setInShadowAnnotation = true),
		@Var(name = "controllerAnnotations", expr = "#{controllers}", annotation = JapkitWebScaffold.class) })
@ResourceTemplate.List({
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "application.jspx", pathExpr = "i18n",
				nameExpr = "application.properties", location = ResourceLocation.WEBINF),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "menu.jspx", pathExpr = "views",
				location = ResourceLocation.WEBINF) })
@GenerateClass()
public @interface JapkitWebApplication {
	boolean shadow() default false;

	Class<?>[] controllers() default {};
}
