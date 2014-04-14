package de.stefanocke.japkit.roo.japkit.web;

import java.util.Arrays;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.roo.base.web.ControllerUtil;

@Template(vars=@Var(name="dateTimeFormatAnnotations", expr="#{datetimeProperties}", annotation=DateTimeFormat.class))
public abstract class ControllerMembers {
	@Method(imports = ControllerUtil.class,
			bodyExpr = "if (bindingResult.hasErrors()) {\n"
					+ "\tpopulateEditForm(uiModel, fbo);\n"
					+ "\treturn \"#{path}/create\";\n"
					+ "}\n"
					+ "uiModel.asMap().clear();\n"
					+ "crudOperations().persist(fbo);\n"
					+ "return \"redirect:/#{path}/\" + ControllerUtil.encodeUrlPathSegment(fbo.getId().toString(), httpServletRequest);\n")
	@ParamNames({ "fbo", "bindingResult", "uiModel", "httpServletRequest" })
	@RequestMapping(method = RequestMethod.POST, produces = "text/html")
	public abstract String create(@Valid FormBackingObject fbo, BindingResult bindingResult, Model uiModel,
			HttpServletRequest httpServletRequest);
	
	@Method(imports = ControllerUtil.class, /* activation=@Matcher(condition="#{hasDatetimeProperties}"),*/ 
			bodyExpr="<%datetimeProperties.each{%>uiModel.addAttribute(\"${fboShortId}_${it.name.toLowerCase()}_date_format\", ControllerUtil.patternForStyle(getDateTimeFormat${it.name.toFirstUpper}()));\n<%}%>", 
			bodyLang="GStringTemplateInline")
	@ParamNames("uiModel") 
	abstract void addDateTimeFormatPatterns(Model uiModel);
	
	@Method(iterator = "#{datetimeProperties}", nameExpr="getDateTimeFormat#{element.name.toFirstUpper}",
			vars=@Var(name="dtfAnnotation", expr="#{element}", annotation=DateTimeFormat.class),
			bodyExpr="return \"#{dtfAnnotation.style}\";")
	abstract String getDateTimeFormat();
	
	@Method(imports = {Arrays.class}, /* activation=@Matcher(condition="#{hasDatetimeProperties}"),*/
			//TODO: Eigentlich singleValueType.
			bodyExpr="<%enumProperties.each{%>uiModel.addAttribute(\"${it.name}s\", Arrays.asList(${ec.typeRef(it.type)}.values()));\n<%}%>", 
			bodyLang="GStringTemplateInline")
	@ParamNames("uiModel") 
	abstract void addEnums(Model uiModel);

	@Method(bodyExpr = "populateEditForm(uiModel, new ${ec.typeRef(fbo)}());\\n"
			+ "return \\\"${path}/create\\\";", //TODO: Help with escaping here.
			bodyLang = "GString")
	@ParamNames({ "uiModel" })
	@RequestMapping(params = "form", produces = "text/html")
	public abstract String createForm(Model uiModel);

	@Method(bodyExpr = "uiModel.addAttribute(\"#{modelAttribute}\", crudOperations().find(id));\n"
			+ "uiModel.addAttribute(\"itemId\", id);\n"
			+ "addDateTimeFormatPatterns(uiModel);\n" 
			+ "return \"#{path}/show\";")
	@ParamNames({ "id", "uiModel" })
	@RequestMapping(produces = "text/html", value = "/{id}")
	public abstract String show(@PathVariable("id") Long id, Model uiModel);

	@Method(bodyExpr = "if (page != null || size != null) {\n"
			+ "\tint sizeNo = size == null ? 10 : size.intValue();\n"
			+ "\tfinal int firstResult = page == null ? 0 : (page.intValue() - 1) * sizeNo;\n"
			+ "\tuiModel.addAttribute(\"#{modelAttribute}s\", crudOperations().findEntries(firstResult, sizeNo, sortFieldName, sortOrder));\n"
			+ "\tfloat nrOfPages = (float) crudOperations().count() / sizeNo;\n"
			+ "\tuiModel.addAttribute(\"maxPages\", (int) ((nrOfPages > (int) nrOfPages || nrOfPages == 0.0) ? nrOfPages + 1 : nrOfPages));\n"
			+ "} else {\n"
			+ "\tuiModel.addAttribute(\"#{modelAttribute}s\", crudOperations().findAll(sortFieldName, sortOrder));\n"
			+ "}"
			+ "addDateTimeFormatPatterns(uiModel);\n" 
			+ "return \"#{path}/list\";\n")
	@RequestMapping(produces = "text/html")
	@ParamNames({ "page", "size", "sortFieldName", "sortOrder", "uiModel" })
	public abstract String list(@RequestParam(value = "page", required = false) Integer page,
			@RequestParam(value = "size", required = false) Integer size,
			@RequestParam(value = "sortFieldName", required = false) String sortFieldName,
			@RequestParam(value = "sortOrder", required = false) String sortOrder, Model uiModel);

	@Method(imports = ControllerUtil.class,
			bodyExpr = "if (bindingResult.hasErrors()) {\n"
					+ "\tpopulateEditForm(uiModel, fbo);\n"
					+ "\treturn \"#{path}/update\";\n"
					+ "}\n"
					+ "uiModel.asMap().clear();\n"
					+ "crudOperations().merge(fbo);\n"
					+ "return \"redirect:/#{path}/\" + ControllerUtil.encodeUrlPathSegment(fbo.getId().toString(), httpServletRequest);\n")
	@ParamNames({ "fbo", "bindingResult", "uiModel", "httpServletRequest" })
	@RequestMapping(produces = "text/html", method = RequestMethod.PUT)
	public abstract String update(@Valid FormBackingObject fbo, BindingResult bindingResult, Model uiModel,
			HttpServletRequest httpServletRequest);

	@Method(bodyExpr = "populateEditForm(uiModel, crudOperations().find(id));\n"
			+ "return \"#{path}/update\";")
	@ParamNames({ "id", "uiModel" })
	@RequestMapping(value = "/{id}", params = "form", produces = "text/html")
	public abstract String updateForm(@PathVariable("id") Long id, Model uiModel);

	@Method(bodyExpr = "crudOperations().remove(id);\n"
			+ "uiModel.asMap().clear();\n"
			+ "uiModel.addAttribute(\"page\", (page == null) ? \"1\" : page.toString());\n"
			+ "uiModel.addAttribute(\"size\", (size == null) ? \"10\" : size.toString());\n"
			+ "return \"redirect:/#{path}\";")
	@ParamNames({ "id", "page", "size", "uiModel" })
	@RequestMapping(produces = "text/html", method = RequestMethod.DELETE, value = "/{id}")
	public abstract String delete(@PathVariable("id") Long id,
			@RequestParam(required = false, value = "page") Integer page, @RequestParam(required = false,
					value = "size") Integer size, Model uiModel);

	//TODO: Conditional calls to addDateTimeFormatPatterns?
	@Method(bodyExpr = "uiModel.addAttribute(\"#{modelAttribute}\", fbo);\n" +
			"addDateTimeFormatPatterns(uiModel);\n" +
			"addEnums(uiModel);\n"
			)
	@ParamNames({ "uiModel", "fbo" })
	abstract void populateEditForm(Model uiModel, FormBackingObject fbo);
	
	//Test
}
