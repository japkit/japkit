package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.ResourceLocation;
import de.stefanocke.japkit.metaannotations.ResourceTemplate;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.metaannotations.TypeQuery;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.WEB_APP, vars={
		@Var(name = "toHtmlId", isFunction=true, expr="#{src.toString().replace('.','_').toLowerCase()}" ),
		@Var(name = "controllers", ifEmpty=true, typeQuery = @TypeQuery(annotation = JapkitWebScaffold.class, shadow = true)),
		@Var(name = "controllerAnnotations", expr = "#{controllers}", annotation = JapkitWebScaffold.class) })
@ResourceTemplate.List({
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "application.jspx", pathExpr = "i18n",
				nameExpr = "application.properties", location = ResourceLocation.WEBINF),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "menu.jspx", pathExpr = "views",
				location = ResourceLocation.WEBINF) })
@Clazz()
public @interface JapkitWebApplication {
	boolean shadow() default false;

	Class<?>[] controllers() default {};
}
