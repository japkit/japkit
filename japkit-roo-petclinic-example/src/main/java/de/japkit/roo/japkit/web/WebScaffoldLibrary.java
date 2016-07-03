package de.japkit.roo.japkit.web;

import javax.persistence.Id;
import javax.persistence.Version;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Library;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Properties;
import de.japkit.metaannotations.TypeQuery;
import de.japkit.roo.japkit.application.DTO;

@RuntimeMetadata
@Library(annotationImports={TableColumn.class, JapkitWebScaffold.class})
public class WebScaffoldLibrary {
	
	@Function(expr="#{src.toString().replace('.','_').toLowerCase()}")
	class toHtmlId{}
	
	@Function(expr = "#{fboShortId}_#{src.name.toLowerCase()}_date_format")
	class dtfModelAttr{}
	
	@Matcher(singleValueTypeAnnotations = DTO.class)
	class isDTO{}
	
	@Matcher(annotations=TableColumn.class)
	class isTableColumn{}
	
	@TypeQuery(annotation = ViewModel.class, shadow = true, unique = true, filterAV = "formBackingObject")
	class findViewModel{}
	
	@TypeQuery(annotation = JapkitWebScaffold.class, shadow = true)
	class findAllControllers{} 
	
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
