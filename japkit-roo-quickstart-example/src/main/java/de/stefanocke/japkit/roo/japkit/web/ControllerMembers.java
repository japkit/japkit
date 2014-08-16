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

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Param;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.base.web.ControllerUtil;

@Controller
@RequestMapping("/$path$")
@RuntimeMetadata
@Template()
public abstract class ControllerMembers {
	
	/**
	 * @japkit.bodyCode <pre>
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
	@RequestMapping(method = RequestMethod.POST, produces = "text/html")
	public abstract String create(@Valid FormBackingObject fbo, BindingResult bindingResult, Model uiModel,
			HttpServletRequest httpServletRequest);

	/**
	 * @japkit.bodyCode 
	 * <code>uiModel.addAttribute("#{src.dtfModelAttr}", ControllerUtil.patternForStyle(getDateTimeFormat#{src.name.toFirstUpper}()));</code>
	 */
	@Method(imports = ControllerUtil.class,	bodyIterator = "datetimeProperties")
	abstract void addDateTimeFormatPatterns(Model uiModel);

	/**
	 * @japkit.bodyCode <code>return "#{dtfAnnotation.style}";</code>
	 */
	@Method(src = "datetimeProperties", srcVar="p", nameExpr = "getDateTimeFormat#{p.name.toFirstUpper}", vars = @Var(
			name = "dtfAnnotation", expr = "#{p}", annotation = DateTimeFormat.class))
	abstract String getDateTimeFormat();

	//TODO: Eigentlich singleValueType.
	/**
	 * @japkit.bodyCode <code>uiModel.addAttribute("${src.name}s", Arrays.asList(${src.type.name}.values()));</code>
	 */
	@Method(imports = Arrays.class, bodyIterator="enumProperties")
	abstract void addEnumChoices(Model uiModel);
	
	//TODO: Eigentlich singleValueType.
	/**
	 * @japkit.bodyCode <code>uiModel.addAttribute("${src.name}Choices", get${src.name.toFirstUpper}Choices());</code>
	 */
	@Method(bodyIterator="entityProperties")
	abstract void addEntityChoices(Model uiModel);

	/**
	 * @japkit.bodyCode <pre>
	 * <code>
	 * populateEditForm(uiModel, new ${fbo.code}()); 
	 * return "${path}/create";
	 * </code>
	 * </pre>
	 */
	@Method(bodyLang = "GStringTemplateInline")
	@RequestMapping(params = "form", produces = "text/html")
	public abstract String createForm(Model uiModel);

	/**
	 * @japkit.bodyCode <pre>
	 * <code>
	 * uiModel.addAttribute("#{modelAttribute}", crudOperations().find(id));
	 * uiModel.addAttribute("itemId", id);
	 * addDateTimeFormatPatterns(uiModel);
	 * return "#{path}/show";
	 * </code>
	 * </pre>
	 */
	
	@Method
	@RequestMapping(produces = "text/html", value = "/{id}")
	public abstract String show(@PathVariable("id") Long id, Model uiModel);

	/**
	 * @japkit.bodyCode <pre>
	 * <code>
	 * if (page != null || size != null) {
	 * 	int sizeNo = size == null ? 10 : size.intValue();
	 * 	final int firstResult = page == null ? 0 : (page.intValue() - 1) * sizeNo;
	 * 	uiModel.addAttribute("#{modelAttribute}s", crudOperations().findEntries(firstResult, sizeNo, sortFieldName, sortOrder));
	 * 	float nrOfPages = (float) crudOperations().count() / sizeNo;
	 * 	uiModel.addAttribute("maxPages", (int) ((nrOfPages > (int) nrOfPages || nrOfPages == 0.0) ? nrOfPages + 1 : nrOfPages));
	 * } else {
	 * 	uiModel.addAttribute("#{modelAttribute}s", crudOperations().findAll(sortFieldName, sortOrder));
	 * }
	 * addDateTimeFormatPatterns(uiModel);
	 * return "#{path}/list";
	 * </code>
	 * </pre>
	 */
	@Method()
	@RequestMapping(produces = "text/html")
	public abstract String list(@RequestParam(value = "page", required = false) Integer page, @RequestParam(value = "size",
			required = false) Integer size, @RequestParam(value = "sortFieldName", required = false) String sortFieldName, @RequestParam(
			value = "sortOrder", required = false) String sortOrder, Model uiModel);

	/**
	 * @japkit.bodyCode <pre>
	 * <code>
	 * if (bindingResult.hasErrors()) {
	 * 	populateEditForm(uiModel, fbo);
	 * 	return "#{path}/update";
	 * }
	 * uiModel.asMap().clear();
	 * crudOperations().merge(fbo);
	 * return "redirect:/#{path}/" + ControllerUtil.encodeUrlPathSegment(fbo.getId().toString(), httpServletRequest);
	 * </code>
	 * </pre>
	 */
	@Method(imports = ControllerUtil.class)
	@RequestMapping(produces = "text/html", method = RequestMethod.PUT)
	public abstract String update(@Valid FormBackingObject fbo, BindingResult bindingResult, Model uiModel,
			HttpServletRequest httpServletRequest);

	/**
	 * @japkit.bodyCode <pre>
	 * <code>
	 * populateEditForm(uiModel, crudOperations().find(id)); 
	 * return "${path}/update";
	 * </code>
	 * </pre>
	 */
	@Method
	@RequestMapping(value = "/{id}", params = "form", produces = "text/html")
	public abstract String updateForm(@PathVariable("id") Long id, Model uiModel);

	/**
	 * @japkit.bodyCode <pre>
	 * <code>
	 * crudOperations().remove(id);
	 * uiModel.asMap().clear();
	 * uiModel.addAttribute("page", (page == null) ? "1" : page.toString());
	 * uiModel.addAttribute("size", (size == null) ? "10" : size.toString());
	 * return "redirect:/#{path}";
	 * </code>
	 * </pre>
	 */
	@Method
	@RequestMapping(produces = "text/html", method = RequestMethod.DELETE, value = "/{id}")
	public abstract String delete(@PathVariable("id") Long id, @RequestParam(required = false, value = "page") Integer page, @RequestParam(
			required = false, value = "size") Integer size, Model uiModel);

	// TODO: Conditional calls to addDateTimeFormatPatterns?
	/**
	 * @japkit.bodyCode <pre>
	 * <code>	
	 * uiModel.addAttribute("#{modelAttribute}", #{modelAttribute});
	 * addDateTimeFormatPatterns(uiModel);
	 * addEnumChoices(uiModel);
	 * addEntityChoices(uiModel);
	 * </code>
	 * </pre>
	 */
	@Method
	abstract void populateEditForm(Model uiModel, FormBackingObject $modelAttribute$);

}
