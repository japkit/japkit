package de.stefanocke.japkit.roo.japkit.web;

import javax.persistence.Id;
import javax.persistence.Version;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import javax.validation.constraints.Pattern;

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Function;
import de.stefanocke.japkit.metaannotations.Library;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.TypeCategory;
import de.stefanocke.japkit.metaannotations.TypeQuery;
import de.stefanocke.japkit.roo.japkit.application.ApplicationService;
import de.stefanocke.japkit.roo.japkit.application.DTO;

@RuntimeMetadata
@Library(annotationImports={TableColumn.class, Pattern.class})
public class WebScaffoldLibrary {
	
	@Function(expr="#{src.toString().replace('.','_').toLowerCase()}")
	class toHtmlId{}
	
	// Some matchers for categorizing properties
	
	@Matcher(singleValueTypeCategory = TypeCategory.TEMPORAL)
	class isDatetime{}
	
	@Matcher(singleValueType = boolean.class)
	class isBoolean{}
	
	@Matcher(singleValueTypeCategory = TypeCategory.ENUM)
	class isEnum{}
	
	@Matcher(annotations = NotNull.class)
	class isRequired{}
	
	@Matcher(annotations = Past.class)
	class isPast{}
	
	@Function(expr = "#{src.Pattern.regexp}")
	class regexp{}

	// The view properties that have a date or time type
	@Function(expr = "#{isDatetime.filter(viewProperties)}")
	class datetimeProperties{}
	
	@Function(expr = "#{!datetimeProperties.isEmpty()}")
	class hasDatetimeProperties{}

	@Function(expr = "#{isEnum.filter(viewProperties)}")
	class enumProperties{}
	
	@Function(expr = "#{fboShortId}_#{src.name.toLowerCase()}_date_format")
	class dtfModelAttr{}
	
	@Matcher(singleValueTypeAnnotations = DTO.class)
	class isDTO{}
	
	
	@TypeQuery(annotation = ApplicationService.class, shadow = true, unique = true, filterAV = "aggregateRoots")
	class findApplicationService{}
	
	@TypeQuery(annotation = ViewModel.class, shadow = true, unique = true, filterAV = "formBackingObject")
	class findViewModel{}
	
	@Properties(includeRules = @Matcher(annotationsNot = { Id.class, Version.class }))
	class viewableProperties{}
	
	/**
	 * @japkit.expr <pre>
	 * <code>
	 * def pNames;  
	 * pNames={p, prfx -> 
	 * 	p.collect{
	 * 		def name = prfx ? prfx+'.'+it.name : it.name;
	 * 		def names = [name];
	 * 		if(it.isVO || it.isDTO)  names.addAll(pNames(it.asType().asElement.properties, name));
	 *	 	names
	 * 	}.flatten()
	 * };
	 * pNames(src, null)
	 * </code>
	 * </pre>
	 */
	@Function(lang = "GroovyScript")
	class allPropertyNames {}
}
