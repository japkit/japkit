package de.stefanocke.japkit.roo.japkit.web;

import javax.lang.model.element.Modifier;
import javax.lang.model.element.TypeElement;
import javax.lang.model.type.TypeMirror;
import javax.persistence.Id;
import javax.persistence.Version;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import de.stefanocke.japkit.metaannotations.AVMapping;
import de.stefanocke.japkit.metaannotations.AVMappingMode;
import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.AnnotationMappingMode;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.GenerateClass;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Members;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.ResourceLocation;
import de.stefanocke.japkit.metaannotations.ResourceTemplate;
import de.stefanocke.japkit.metaannotations.TypeCategory;
import de.stefanocke.japkit.metaannotations.TypeQuery;
import de.stefanocke.japkit.roo.japkit.JapJpaRepository;
import de.stefanocke.japkit.roo.japkit.JapkitEntity;

@Var.List({
		@Var(name = "fbo", triggerAV = "formBackingObject"),
		@Var(name = "fboElement", type = TypeElement.class, expr = "#{fbo.asElement}"),
		@Var(name = "entityAnnotation", expr = "#{fboElement}", annotation = JapkitEntity.class),
		@Var(name = "fboName", type = String.class, triggerAV = "fboName", expr = "#{fboElement.simpleName.toString()}",
				setInShadowAnnotation = true),
		@Var(name = "fboPluralName", type = String.class, triggerAV = "fboPluralName", expr = "#{fboName}s", setInShadowAnnotation = true),
		@Var(name = "path", type = String.class, triggerAV = "path", expr = "#{fboPluralName.toLowerCase()}", setInShadowAnnotation = true),
		@Var(name = "modelAttribute", type = String.class, triggerAV = "modelAttribute", expr = "#{fboName.toFirstLower}",
				setInShadowAnnotation = true),
		// For making IDs in JSPs unique
		@Var(name = "fboFqnId", triggerAV = "fqnId", expr = "#{fboElement.qualifiedName.toString().replace('.','_').toLowerCase()}",
				setInShadowAnnotation = true),
		@Var(name = "fboShortId", triggerAV = "shortId", expr = "#{fboName.toLowerCase()}", setInShadowAnnotation = true),

		@Var(name = "viewModel", triggerAV = "viewModel", typeQuery = @TypeQuery(
				annotation = ViewModel.class, shadow = true, unique = true, filterAV = "formBackingObject", inExpr = "#{fbo}"),
				setInShadowAnnotation = true),
		
		// The properties to show
		@Var(name = "viewProperties", propertyFilter = @Properties(sourceClass = ViewModelSelector.class, includeRules = @Matcher(
				srcAnnotationsNot = { Id.class, Version.class }))),
		@Var(name = "explicitTableProperties", expr = "#{viewProperties}", matcher=@Matcher(srcAnnotations=ShowInTable.class)),
		@Var(name = "tableProperties", expr = "#{explicitTableProperties.isEmpty() ? viewProperties : explicitTableProperties}"),

		@Var(name = "repository", type = TypeMirror.class, triggerAV = "repository", typeQuery = @TypeQuery(
				annotation = JapJpaRepository.class, shadow = true, unique = true, filterAV = "domainType", inExpr = "#{fbo}"),
				setInShadowAnnotation = true),

		// Some matchers for categorize properties
		@Var(name = "isDatetime", isFunction = true, matcher = @Matcher(srcSingleValueTypeCategory = TypeCategory.TEMPORAL)),
		@Var(name = "isBoolean", isFunction = true, matcher = @Matcher(srcSingleValueType = boolean.class)),
		@Var(name = "isEnum", isFunction = true, matcher = @Matcher(srcSingleValueTypeCategory = TypeCategory.ENUM)),
		@Var(name = "isRequired", isFunction = true, matcher = @Matcher(srcAnnotations = NotNull.class)),
		@Var(name = "isPast", isFunction = true, matcher = @Matcher(srcAnnotations = Past.class)),
		@Var(name = "patternAnnotation", isFunction = true, annotation=Pattern.class),
		@Var(name = "regexp", isFunction = true, expr = "#{element.patternAnnotation.regexp}"),
		// The view properties that have a date or time type
		@Var(name = "datetimeProperties", expr = "#{isDatetime.filter(viewProperties)}"),
		@Var(name = "hasDatetimeProperties", expr = "#{!datetimeProperties.isEmpty()}"),
		@Var(name = "enumProperties", expr = "#{isEnum.filter(viewProperties)}"),
		@Var(name = "dtfModelAttr", isFunction = true, expr = "#{fboShortId}_#{element.name.toLowerCase()}_date_format")

})
@GenerateClass(
		classSuffixToRemove = "Def",
		classSuffixToAppend = "",
		modifier = Modifier.PUBLIC,
		annotationMappings = {
				@AnnotationMapping(targetAnnotation = JapkitWebScaffold.class, mode = AnnotationMappingMode.MERGE,
						valueMappings = { @AVMapping(name = "propertyNames", mode = AVMappingMode.IGNORE,
								expr = "viewProperties.collect{it.name}", lang = "GroovyScript"), }),
				@AnnotationMapping(targetAnnotation = Controller.class),
				@AnnotationMapping(targetAnnotation = RequestMapping.class, valueMappings = @AVMapping(name = "value", expr = "/#{path}")) },
		members = {
				@Members(ControllerMembers.class),
				@Members(activation = @Matcher(condition = "#{entityAnnotation.activeRecord}"), value = ControllerMembersActiveRecord.class),
				@Members(activation = @Matcher(condition = "#{repository != null && !entityAnnotation.activeRecord}"),
						value = ControllerMembersJpaRepository.class) })
@ResourceTemplate.List({
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "createOrUpdate.jspx", pathExpr = "views/#{path}",
				nameExpr = "create.jspx", location = ResourceLocation.WEBINF, vars = @Var(name = "update", expr = "#{false}")),
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
	Class<? extends JpaRepository>[] repository() default {};

	/**
	 * 
	 * @return the unique id for the fbo class used in JSPs and i18n
	 */
	String fqnId() default "";

	String shortId() default "";

	String fboName() default "";

	String fboPluralName() default "";

	// For i18n. TODO: Reconsider
	String[] propertyNames() default {};
}
