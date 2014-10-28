package de.stefanocke.japkit.roo.japkit.web;

import javax.lang.model.element.Modifier;
import javax.lang.model.element.TypeElement;
import javax.lang.model.type.TypeMirror;
import javax.persistence.Id;
import javax.persistence.Version;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import javax.validation.constraints.Pattern;

import org.springframework.data.jpa.repository.JpaRepository;

import de.stefanocke.japkit.metaannotations.AV;
import de.stefanocke.japkit.metaannotations.AVMode;
import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.AnnotationMode;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.SingleValue;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.ResourceLocation;
import de.stefanocke.japkit.metaannotations.ResourceTemplate;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.metaannotations.TypeCategory;
import de.stefanocke.japkit.metaannotations.TypeQuery;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.japkit.Layers;
import de.stefanocke.japkit.roo.japkit.application.ApplicationService;
import de.stefanocke.japkit.roo.japkit.application.CommandMethod;
import de.stefanocke.japkit.roo.japkit.domain.JapJpaRepository;
import de.stefanocke.japkit.roo.japkit.domain.JapkitEntity;
import de.stefanocke.japkit.roo.japkit.web.ControllerMembers.Create.Command;

@Trigger(layer=Layers.CONTROLLERS, vars={
		@Var(name = "fbo", expr = "#{formBackingObject}"),
		@Var(name = "fboElement", type = TypeElement.class, expr = "#{fbo.asElement}"),
		@Var(name = "entityAnnotation", expr = "#{fboElement}", annotation = JapkitEntity.class),
		@Var(name = "fboName", type = String.class, ifEmpty=true, expr = "#{fboElement.simpleName.toString()}"),
		@Var(name = "fboPluralName", type = String.class, ifEmpty=true, expr = "#{fboName}s"),
		@Var(name = "path", type = String.class, ifEmpty=true, expr = "#{fboPluralName.toLowerCase()}"),
		//@Var(name = "path", expr="foo", ifEmpty=true),
		@Var(name = "modelAttribute", type = String.class, ifEmpty=true, expr = "#{fboName.toFirstLower}"),
		// For making IDs in JSPs unique
		@Var(name = "fboFqnId", expr = "#{fboElement.qualifiedName.toString().replace('.','_').toLowerCase()}"),
		@Var(name = "fboShortId", expr = "#{fboName.toLowerCase()}"),

		@Var(name = "viewModel", ifEmpty=true, typeQuery = @TypeQuery(
				annotation = ViewModel.class, shadow = true, unique = true, filterAV = "formBackingObject", inExpr = "#{fbo}")),
		
		// The properties to show
		@Var(name = "viewProperties", propertyFilter = @Properties(sourceClass = ViewModelSelector.class, includeRules = @Matcher(
				annotationsNot = { Id.class, Version.class }))),
		@Var(name = "explicitTableProperties", expr = "#{viewProperties}", matcher=@Matcher(annotations=TableColumn.class)),
		@Var(name = "tableProperties", expr = "#{explicitTableProperties.isEmpty() ? viewProperties : explicitTableProperties}"),
		@Var(name = "columnAnnotation", isFunction=true, annotation = TableColumn.class),

		// Some matchers for categorize properties
		@Var(name = "isDatetime", isFunction = true, matcher = @Matcher(singleValueTypeCategory = TypeCategory.TEMPORAL)),
		@Var(name = "isBoolean", isFunction = true, matcher = @Matcher(singleValueType = boolean.class)),
		@Var(name = "isEnum", isFunction = true, matcher = @Matcher(singleValueTypeCategory = TypeCategory.ENUM)),
		@Var(name = "isRequired", isFunction = true, matcher = @Matcher(annotations = NotNull.class)),
		@Var(name = "isPast", isFunction = true, matcher = @Matcher(annotations = Past.class)),
		@Var(name = "patternAnnotation", isFunction = true, annotation=Pattern.class),
		@Var(name = "regexp", isFunction = true, expr = "#{src.patternAnnotation.regexp}"),
		// The view properties that have a date or time type
		@Var(name = "datetimeProperties", expr = "#{isDatetime.filter(viewProperties)}"),
		@Var(name = "hasDatetimeProperties", expr = "#{!datetimeProperties.isEmpty()}"),
		@Var(name = "enumProperties", expr = "#{isEnum.filter(viewProperties)}"),
		@Var(name = "dtfModelAttr", isFunction = true, expr = "#{fboShortId}_#{src.name.toLowerCase()}_date_format"),
		
		@Var(name = "isEntity", isFunction = true,  matcher = @Matcher(singleValueTypeAnnotations = JapkitEntity.class)),
		@Var(name = "entityProperties", expr = "#{isEntity.filter(viewProperties)}"),
		@Var(name = "relatedEntities", expr = "entityProperties.collect{it.singleValueType.asElement()}", lang="GroovyScript"),
		
		//TODO: Etwas unschön, dass bei functions nur Element als Parameter erlaubt ist. Zumindest noch Type zulassen, wenn schon nicht Object.
		@Var(name = "findRepository", isFunction = true, typeQuery = @TypeQuery(
				annotation = JapJpaRepository.class, shadow = true, unique = true, filterAV = "domainType", inExpr = "#{src.asType()}")),
				
		@Var(name = "repository", type = TypeMirror.class, ifEmpty = true, expr="#{fboElement.findRepository}"),
		
		@Var(name = "applicationService", ifEmpty = true, typeQuery = @TypeQuery(
				annotation = ApplicationService.class, shadow = true, unique = true, filterAV = "aggregateRoots", inExpr = "#{fbo}")),
		@Var(name="createCommands", expr="#{applicationService.asElement.declaredMethods}", 
				matcher=@Matcher(annotations=CommandMethod.class, condition="#{src.returnType.isSame(fbo)}"))

})
@Clazz(
		nameSuffixToRemove = "Def",
		nameSuffixToAppend = "",
		//superclassTypeArgs=FormBackingObject.class,
		
		modifiers = Modifier.PUBLIC,
		annotations = {
				@Annotation(targetAnnotation = JapkitWebScaffold.class, mode = AnnotationMode.MERGE,
						values = { @AV(name = "propertyNames", mode = AVMode.IGNORE,
								expr = "viewProperties.collect{it.name}", lang = "GroovyScript"), })},
		customBehaviorActivation=@Matcher(condition="#{triggerAnnotation.customBehavior}"),
		templates = {
				@TemplateCall(ControllerMembers.class),
				@TemplateCall(ControllerMembersJpaRepository.class) ,
				@TemplateCall(ControllerConverterProviderMembers.class)
				})
@ResourceTemplate.List({
		@ResourceTemplate(src="#{createCommands.get(0)}", srcVar="cmdMethod", 
				templateLang = "GStringTemplate", templateName = "createOrUpdate.jspx", pathExpr = "views/#{path}",
				nameExpr = "create.jspx", location = ResourceLocation.WEBINF, 
				vars ={ @Var(name = "update", expr = "#{false}"), 
					@Var(name="command", expr="#{cmdMethod.parameters.get(0).asType()}"),
					@Var(name="modelAttribute", expr="#{command.asElement().simpleName.toFirstLower}"),
					@Var(name = "viewProperties", propertyFilter = @Properties(sourceClass = Command.class, includeRules = @Matcher(
							annotationsNot = { Id.class, Version.class }))),
				}),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "createOrUpdate.jspx", pathExpr = "views/#{path}",
				nameExpr = "update.jspx", location = ResourceLocation.WEBINF, vars = @Var(name = "update", expr = "#{true}")),
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
