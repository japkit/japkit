package de.japkit.roo.japkit.web;

import java.util.Arrays;

import javax.annotation.Resource;
import javax.validation.Valid;

import org.springframework.stereotype.Component;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Var;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.roo.base.web.ControllerUtil;
import de.japkit.roo.base.web.ResourceBundleNameProvider;
import de.japkit.roo.japkit.CommonLibrary;
import de.japkit.roo.japkit.CommonLibrary.nameFirstLower;

@Controller
@RequestMapping("/$path$")
@RuntimeMetadata
@Template(libraries=CommonLibrary.class)
public abstract class ControllerMembers {
	@ClassSelector
	class ApplicationService{}
	
	@Resource
	private ApplicationService applicationService;
	
	@Template(src="#{createCommands.get(0)}", srcVar="cmdMethod")
	abstract class Create{
		@Var(expr="#{cmdMethod.parameters.get(0).asType()}")
		class Command{}
		
		@Var(fun={Command.class, nameFirstLower.class})
		class cmdName{}
		
		/**
		 * @japkit.bodyCode <pre>
		 * <code>
		 * if (bindingResult.hasErrors()) {
		 * 	populateCreateForm(uiModel, #{cmdName});
		 * 	return "#{path}/create";
		 * }
		 * uiModel.asMap().clear();
		 * #{fbo.code} fbo =  applicationService.#{cmdMethod.simpleName}(#{cmdName});
		 * redirectAttributes.addAttribute("id", fbo.getId());
		 * return "redirect:/#{path}/{id}";
		 * </code>
		 * </pre>
		 */
		@Method(imports = ControllerUtil.class)
		@RequestMapping(method = RequestMethod.POST, produces = "text/html")
		public abstract String create(@Valid Command $cmdName$, BindingResult bindingResult, Model uiModel,
				RedirectAttributes redirectAttributes);
	
		
		/**
		 * @japkit.bodyCode <pre>
		 * <code>
		 * populateCreateForm(uiModel, new #{command.code}()); 
		 * return "#{path}/create";
		 * </code>
		 * </pre>
		 */
		@Method()
		@RequestMapping(params = "form", produces = "text/html")
		public abstract String createForm(Model uiModel);
		
		/**
		 * @japkit.bodyCode <pre>
		 * <code>	
		 * uiModel.addAttribute("#{cmdName}", command);
		 * addDateTimeFormatPatterns(uiModel);
		 * addEnumChoices(uiModel);
		 * addEntityChoices(uiModel);
		 * </code>
		 * </pre>
		 */
		abstract void populateCreateForm(Model uiModel, Command command);
	
	}
	
	/**
	 * @japkit.bodyCode <pre>
	 * <code>	
	 * uiModel.addAttribute("updateCommands", UPDATE_COMMANDS);
	 * </code>
	 * </pre>
	 */
	public static void populateUpdateCommands(Model uiModel){};
	
	
	/**
	 * @japkit.initCode <code>'{'+updateCommands.collect{'"'+it.simpleName+'"'}.join(', ')+'}'</code>
	 */
	@Field(initLang="GroovyScript")  //TODO: Modus, der wie bei AVs funktioniert, damit man den Wert auch direkt setzen kann
	public static String[] UPDATE_COMMANDS;
	
	
	@Clazz(nameExpr="#{fboName}ResourceBundleNameProvider")
	@Template
	@Component
	public abstract class ResourceBundleNameProviderForCommands implements ResourceBundleNameProvider{
		/**
		 * @japkit.bodyCode <pre>
		 * <code>	
		 * return new String[]{<%= (updateCommands.toSet() + createCommands.toSet()).collect{'"'+path+'/'+it.simpleName+'"'}.join(', ') %>};
		 * </code>
		 * </pre>
		 */
		@Method(bodyLang="GStringTemplateInline")
		public abstract String[] getResourceBundleBaseNames();
	}
	
	
	
	
	@Template(src="#{updateCommands}", srcVar="cmdMethod", 
			vars={@Var(name="command", expr="#{cmdMethod.parameters.get(0).asType()}"),
			@Var(name="cmdNameU", expr="#{command.simpleName}"),
			@Var(name="cmdName", expr="#{cmdNameU.toFirstLower}"),
			@Var(name="cmdMethodName", expr="#{cmdMethod.simpleName.toString()}" )})
	abstract class Update{
		/**
		 * @japkit.bodyCode <pre>
		 * <code>
		 * if (bindingResult.hasErrors()) {
		 * 	populate#{cmdNameU}Form(uiModel, #{cmdName});
		 * 	return "#{path}/#{cmdMethodName}";
		 * }
		 * uiModel.asMap().clear();
		 * applicationService.#{cmdMethodName}(#{cmdName});
		 * redirectAttributes.addAttribute("id", #{cmdName}.getId());
		 * return "redirect:/#{path}/{id}";
		 * </code>
		 * </pre>
		 */
		@Method(imports = ControllerUtil.class)
		@RequestMapping(value = "/$cmdMethodName$", method = RequestMethod.POST, produces = "text/html")
		public abstract String $cmdName$(@Valid Command $cmdName$, BindingResult bindingResult, Model uiModel,
				RedirectAttributes redirectAttributes);
	
		@ClassSelector
		class Command{}
		
		/**
		 * @japkit.bodyCode <pre>
		 * <code>
		 * populate#{cmdNameU}Form(uiModel, applicationService.find#{fboName}(id, null)); 
		 * return "#{path}/#{cmdMethodName}";
		 * </code>
		 * </pre>
		 */
		@Method()
		@RequestMapping(value = "/{id}/$cmdMethodName$",  produces = "text/html")
		public abstract String $cmdName$Form(@PathVariable("id") Long id, Model uiModel);
		
		/**
		 * @japkit.bodyCode <pre>
		 * <code>	
		 * uiModel.addAttribute("#{cmdName}", command);
		 * addDateTimeFormatPatterns(uiModel);
		 * addEnumChoices(uiModel);
		 * addEntityChoices(uiModel);
		 * </code>
		 * </pre>
		 */
		abstract void populate$cmdNameU$Form(Model uiModel, Object command); //TODO: Instead of relying on UI Binding here, the AppService could provide factory methods for commands
	
	}
	
	/**
	 * @japkit.bodyCode 
	 * <code>uiModel.addAttribute("#{src.dtfModelAttr}", ControllerUtil.patternForStyle(getDateTimeFormat#{src.name.toFirstUpper}()));</code>
	 */
	@Method(imports = ControllerUtil.class,	bodyIterator = "datetimeProperties")
	abstract void addDateTimeFormatPatterns(Model uiModel);

	/**
	 * @japkit.bodyCode <code>return "#{dateTimeFormatStyle()}";</code>
	 */
	@Method(src = "datetimeProperties")
	abstract String getDateTimeFormat$nameFirstUpper$();

	//TODO: Eigentlich singleValueType.
	/**
	 * @japkit.bodyCode <code>uiModel.addAttribute("${src.name}s", Arrays.asList(${src.type.name}.values()));</code>
	 */
	@Method(imports = Arrays.class, bodyIterator="enumProperties")
	abstract void addEnumChoices(Model uiModel);

	/**
	 * @japkit.bodyCode <pre>
	 * <code>
	 * uiModel.addAttribute("#{modelAttribute}", crudOperations().find(id));
	 * uiModel.addAttribute("itemId", id);
	 * addDateTimeFormatPatterns(uiModel);
	 * populateUpdateCommands(uiModel);
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
	 * populateUpdateCommands(uiModel);
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
	abstract void populateEditForm(Model uiModel, FormBackingObject $modelAttribute$);

}
