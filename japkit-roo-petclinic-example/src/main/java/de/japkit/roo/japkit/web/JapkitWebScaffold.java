package de.japkit.roo.japkit.web;

import javax.lang.model.element.Modifier;
import javax.lang.model.type.TypeMirror;

import org.springframework.data.jpa.repository.JpaRepository;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.ResourceLocation;
import de.japkit.metaannotations.ResourceTemplate;
import de.japkit.metaannotations.SingleValue;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.Trigger;
import de.japkit.metaannotations.Var;
import de.japkit.roo.japkit.Layers;
import de.japkit.roo.japkit.application.ApplicationServiceLibrary;
import de.japkit.roo.japkit.application.ApplicationServiceLibrary.findApplicationService;
import de.japkit.roo.japkit.application.ApplicationServiceLibrary.findCreateCommandMethods;
import de.japkit.roo.japkit.application.ApplicationServiceLibrary.findUpdateCommandMethods;
import de.japkit.roo.japkit.domain.DomainLibrary;
import de.japkit.roo.japkit.domain.DomainLibrary.findRepository;
import de.japkit.roo.japkit.domain.DomainLibrary.isDatetime;
import de.japkit.roo.japkit.domain.DomainLibrary.isEntity;
import de.japkit.roo.japkit.domain.DomainLibrary.isEnum;
import de.japkit.roo.japkit.web.WebScaffoldLibrary.allPropertyNames;
import de.japkit.roo.japkit.web.WebScaffoldLibrary.findViewModel;
import de.japkit.roo.japkit.web.WebScaffoldLibrary.isTableColumn;
import de.japkit.roo.japkit.web.WebScaffoldLibrary.toHtmlId;
import de.japkit.roo.japkit.web.WebScaffoldLibrary.viewableProperties;

@RuntimeMetadata
@Trigger(layer=Layers.CONTROLLERS, 
	libraries={DomainLibrary.class, ApplicationServiceLibrary.class, WebScaffoldLibrary.class},
	vars={
		@Var(name = "fbo", expr = "#{formBackingObject}"),
		@Var(name = "fboName", type = String.class, ifEmpty=true, expr = "#{fbo.simpleName.toString()}"),
		@Var(name = "fboPluralName", type = String.class, ifEmpty=true, expr = "#{fboName}s"),
		@Var(name = "path", type = String.class, ifEmpty=true, expr = "#{fboPluralName.toLowerCase()}"),
		@Var(name = "modelAttribute", type = String.class, ifEmpty=true, expr = "#{fboName.toFirstLower}"),
		
		// For making IDs in JSPs unique
		@Var(name = "fboFqnId", expr = "#{fbo.qualifiedName}", fun=toHtmlId.class),	
		@Var(name = "fboShortId", expr = "#{fboName.toLowerCase()}"),

		@Var(name = "viewModel", expr="#{fbo}", fun=findViewModel.class, nullable=true),
		
		// The properties to show
		@Var(name = "viewProperties", expr="#{viewModel != null ? viewModel : fbo}", fun=viewableProperties.class),
		@Var(name = "datetimeProperties", expr = "#{viewProperties}", filterFun = isDatetime.class),
		@Var(name = "enumProperties", expr = "#{viewProperties}", filterFun = isEnum.class),

		
		@Var(name = "explicitTableProperties", expr = "#{viewProperties}", filterFun = isTableColumn.class),
		@Var(name = "tableProperties", expr = "#{explicitTableProperties.isEmpty() ? viewProperties : explicitTableProperties}"),
				
		@Var(name = "applicationService", expr="#{fbo}", fun=findApplicationService.class),

		@Var(name="createCommands", expr="#{applicationService}", fun=findCreateCommandMethods.class),
		@Var(name="updateCommands", expr="#{applicationService}", fun=findUpdateCommandMethods.class),
		@Var(name = "propertyNames", ifEmpty=true, expr="#{viewProperties}", fun=allPropertyNames.class)		

})
@Clazz(
		nameSuffixToRemove = "Def",
		nameSuffixToAppend = "",
		//superclassTypeArgs=FormBackingObject.class,
		
		modifiers = Modifier.PUBLIC,
		customBehaviorCond="#{triggerAnnotation.customBehavior}",
		templates = {
				@TemplateCall(ControllerMembers.class),
				@TemplateCall(ControllerMembersJpaRepository.class) ,
				@TemplateCall(ControllerFormatterMembers.class)
				})
@ResourceTemplate.List({
		@ResourceTemplate(src="#{createCommands.get(0)}", srcVar="cmdMethod", 
				templateLang = "GStringTemplate", templateName = "createOrUpdate.jspx", pathExpr = "views/#{path}",
				nameExpr = "create.jspx", location = ResourceLocation.WEBINF, 
				vars ={ @Var(name = "update", expr = "#{false}"), 
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="modelAttribute", expr="#{command.simpleName.toFirstLower}"),
					@Var(name = "viewProperties", expr="#{command.properties}"),
				}),
		@ResourceTemplate(src="#{createCommands}", srcVar="cmdMethod",
				templateLang = "GStringTemplate", templateName = "command_i18n.jspx", pathExpr = "i18n/#{path}",
				nameExpr = "#{cmdMethod.simpleName}.properties", location = ResourceLocation.WEBINF, 
				vars = {
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="cmdName", expr="#{cmdMethod.simpleName}"),
					@Var(name = "cmdPropertyNames", expr="#{allPropertyNames(command.properties)}"),
				}),
		@ResourceTemplate(src="#{updateCommands}", srcVar="cmdMethod",
				templateLang = "GStringTemplate", templateName = "createOrUpdate.jspx", pathExpr = "views/#{path}",
				nameExpr = "#{cmdMethod.simpleName.toFirstLower}.jspx", location = ResourceLocation.WEBINF, 
				vars = {
					@Var(name = "update", expr = "#{true}"),
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="modelAttribute", expr="#{command.simpleName.toFirstLower}"),
					@Var(name = "viewProperties", expr="#{command.properties}"),
				}),
		@ResourceTemplate(src="#{updateCommands}", srcVar="cmdMethod",
				templateLang = "GStringTemplate", templateName = "command_i18n.jspx", pathExpr = "i18n/#{path}",
				nameExpr = "#{cmdMethod.simpleName}.properties", location = ResourceLocation.WEBINF, 
				vars = {
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="cmdName", expr="#{cmdMethod.simpleName}"),
					@Var(name = "cmdPropertyNames", expr="#{allPropertyNames(command.properties)}"),
				}),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "show.jspx", location = ResourceLocation.WEBINF,
				pathExpr = "views/#{path}"),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "list.jspx", location = ResourceLocation.WEBINF,
				pathExpr = "views/#{path}") })
public @interface JapkitWebScaffold {

	boolean shadow() default false;

	/**
	 * Every controller is responsible for a single form backing object. The
	 * form backing object defined here class will be exposed in a RESTful way.
	 */
	Class<?> formBackingObject();
	
	Class<?>[] viewModel() default {};

	/**
	 * All view-related artifacts for a specific controller are stored in a
	 * sub-directory under WEB-INF/views/<em>path</em>. The path parameter
	 * defines the name of this sub-directory or path. This path is also used to
	 * define the restful resource in the URL to which the controller is mapped.
	 * 
	 * @return The view path.
	 */
	String path() default "";

	boolean customBehavior() default false;

	/**
	 * 
	 * @return the name of the model attribute for the formBackingObject. By
	 *         default, the class name with first lower case.
	 */
	String modelAttribute() default "";
		
	@SuppressWarnings("rawtypes")
	@SingleValue
	Class<? extends JpaRepository>[] repository() default {};
	
	@Var(type = TypeMirror.class, ifEmpty = true, expr="#{fbo}", fun=findRepository.class)	
	class Repository{};

	@SingleValue
	Class<?>[] applicationService() default {};
	/**
	 * 
	 * @return the unique id for the fbo class used in JSPs and i18n
	 */
	String fboFqnId() default "";

	String fboShortId() default "";

	String fboName() default "";

	String fboPluralName() default "";

	// For i18n. TODO: Reconsider
	String[] propertyNames() default {};
	
	
}
