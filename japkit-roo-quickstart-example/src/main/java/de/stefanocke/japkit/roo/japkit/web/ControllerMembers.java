package de.stefanocke.japkit.roo.japkit.web;

import java.util.Arrays;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import de.stefanocke.japkit.metaannotations.AVMapping;
import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Param;
import de.stefanocke.japkit.metaannotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.base.web.ControllerUtil;

@Controller
@Template(annotationMappings=@AnnotationMapping(targetAnnotation = RequestMapping.class, valueMappings = @AVMapping(name = "value", expr = "/#{path}")))
public abstract class ControllerMembers {
	
	/**
	 * Some comment...
	 * 
	 * @param fbo
	 * 
	 * @japkit.bodyExpr <pre>
	 * <code>
	 * if (bindingResult.hasErrors()) {
	 * 	populateEditForm(uiModel, fbo);
	 * 	return "#{path}/create";
	 * }
	 * uiModel.asMap().clear();
	 * crudOperations().persist(fbo);
	 * return "redirect:/#{path}/" + ControllerUtil.encodeUrlPathSegment(fbo.getId().toString(), httpServletRequest);
	 * </code>
	 * </pre>
	 */
	@Method(imports = ControllerUtil.class)
	@ParamNames({ "fbo", "bindingResult", "uiModel", "httpServletRequest" })
	@RequestMapping(method = RequestMethod.POST, produces = "text/html")
	public abstract String create(@Valid FormBackingObject fbo, BindingResult bindingResult, Model uiModel,
			HttpServletRequest httpServletRequest);

	/**
	 * @japkit.bodyBeforeExpr <code>//blah</code>
	 * 
	 * @japkit.bodyExpr 
	 * <code>uiModel.addAttribute("#{dtfModelAttr.eval(src)}", ControllerUtil.patternForStyle(getDateTimeFormat#{src.name.toFirstUpper}()));</code>
	 * 
	 * @japkit.bodyAfterExpr <code>//blub</code>
	 */
	@Method(imports = ControllerUtil.class,	bodyIterator = "datetimeProperties")
	@ParamNames("uiModel")
	abstract void addDateTimeFormatPatterns(Model uiModel);

	@Method(src = "datetimeProperties", srcVar="p", nameExpr = "getDateTimeFormat#{p.name.toFirstUpper}", vars = @Var(
			name = "dtfAnnotation", expr = "#{p}", annotation = DateTimeFormat.class),
			bodyExpr = "return \"#{dtfAnnotation.style}\";")
	abstract String getDateTimeFormat();

	@Method(
			imports = { Arrays.class }, 
			bodyIterator="enumProperties",
			// TODO: Eigentlich singleValueType.
			bodyExpr = "uiModel.addAttribute(\"${src.name}s\", Arrays.asList(${ec.typeRef(src.type)}.values()));\n"
			)
	@ParamNames("uiModel")
	abstract void addEnumChoices(Model uiModel);
	
	@Method(
			bodyIterator="entityProperties",
			// TODO: Eigentlich singleValueType.
			bodyExpr = "uiModel.addAttribute(\"${src.name}Choices\", get${src.name.toFirstUpper}Choices());\n"
			)
	@ParamNames("uiModel")
	abstract void addEntityChoices(Model uiModel);

	// TODO: Help with escaping here.
	@Method(bodyExpr = "populateEditForm(uiModel, new ${ec.typeRef(fbo)}());\\n" + "return \\\"${path}/create\\\";", bodyLang = "GString")
	@ParamNames({ "uiModel" })
	@RequestMapping(params = "form", produces = "text/html")
	public abstract String createForm(Model uiModel);

	@Method(bodyExpr = "uiModel.addAttribute(\"#{modelAttribute}\", crudOperations().find(id));\n"
			+ "uiModel.addAttribute(\"itemId\", id);\n" + "addDateTimeFormatPatterns(uiModel);\n" + "return \"#{path}/show\";")
	@ParamNames({ "id", "uiModel" })
	@RequestMapping(produces = "text/html", value = "/{id}")
	public abstract String show(@PathVariable("id") Long id, Model uiModel);

	@Method(
			bodyExpr = "if (page != null || size != null) {\n"
					+ "\tint sizeNo = size == null ? 10 : size.intValue();\n"
					+ "\tfinal int firstResult = page == null ? 0 : (page.intValue() - 1) * sizeNo;\n"
					+ "\tuiModel.addAttribute(\"#{modelAttribute}s\", crudOperations().findEntries(firstResult, sizeNo, sortFieldName, sortOrder));\n"
					+ "\tfloat nrOfPages = (float) crudOperations().count() / sizeNo;\n"
					+ "\tuiModel.addAttribute(\"maxPages\", (int) ((nrOfPages > (int) nrOfPages || nrOfPages == 0.0) ? nrOfPages + 1 : nrOfPages));\n"
					+ "} else {\n"
					+ "\tuiModel.addAttribute(\"#{modelAttribute}s\", crudOperations().findAll(sortFieldName, sortOrder));\n" + "}"
					+ "addDateTimeFormatPatterns(uiModel);\n" + "return \"#{path}/list\";\n")
	@RequestMapping(produces = "text/html")
	@ParamNames({ "page", "size", "sortFieldName", "sortOrder", "uiModel" })
	public abstract String list(@RequestParam(value = "page", required = false) Integer page, @RequestParam(value = "size",
			required = false) Integer size, @RequestParam(value = "sortFieldName", required = false) String sortFieldName, @RequestParam(
			value = "sortOrder", required = false) String sortOrder, Model uiModel);

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

	@Method(bodyExpr = "populateEditForm(uiModel, crudOperations().find(id));\n" + "return \"#{path}/update\";")
	@ParamNames({ "id", "uiModel" })
	@RequestMapping(value = "/{id}", params = "form", produces = "text/html")
	public abstract String updateForm(@PathVariable("id") Long id, Model uiModel);

	@Method(bodyExpr = "crudOperations().remove(id);\n" 
			+ "uiModel.asMap().clear();\n"
			+ "uiModel.addAttribute(\"page\", (page == null) ? \"1\" : page.toString());\n"
			+ "uiModel.addAttribute(\"size\", (size == null) ? \"10\" : size.toString());\n" + "return \"redirect:/#{path}\";")
	@ParamNames({ "id", "page", "size", "uiModel" })
	@RequestMapping(produces = "text/html", method = RequestMethod.DELETE, value = "/{id}")
	public abstract String delete(@PathVariable("id") Long id, @RequestParam(required = false, value = "page") Integer page, @RequestParam(
			required = false, value = "size") Integer size, Model uiModel);

	// TODO: Conditional calls to addDateTimeFormatPatterns?
	@Method(bodyExpr = "uiModel.addAttribute(\"#{modelAttribute}\", #{modelAttribute});\n" 
			+ "addDateTimeFormatPatterns(uiModel);\n"
			+ "addEnumChoices(uiModel);\n"
			+ "addEntityChoices(uiModel);\n"
			)
	@ParamNames({ "uiModel", "fbo" })
	abstract void populateEditForm(Model uiModel,  @Param(nameExpr="#{modelAttribute}") FormBackingObject fbo);

}
