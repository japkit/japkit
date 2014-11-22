package de.stefanocke.japkit.groovy

import groovy.lang.GroovyShell;
import groovy.text.GStringTemplateEngine;
import groovy.text.GStringTemplateEngine.GStringTemplate;
import groovy.text.Template;
import groovy.text.XmlTemplateEngine;

import java.io.Writer;
import java.net.URL;
import java.util.Map
import java.util.concurrent.TimeUnit;

import javax.annotation.processing.ProcessingEnvironment;
import javax.tools.Diagnostic;

import org.codehaus.groovy.control.CompilerConfiguration;
import org.codehaus.groovy.runtime.InvokerHelper;
import org.eclipse.xtext.xbase.lib.Pair

import com.google.common.base.Stopwatch;

import de.stefanocke.japkit.el.ELProvider;
import de.stefanocke.japkit.el.ELProviderException;
import de.stefanocke.japkit.el.ElExtensionPropertiesAndMethods;
import de.stefanocke.japkit.el.ElExtensions;
import de.stefanocke.japkit.el.ValueStack

class GroovyELProvider implements ELProvider {



	ThreadLocal<Map<String, Object>> contextMapTL = new ThreadLocal<Map<String, Object>>();

	CompilerConfiguration conf = new CompilerConfiguration().with {
		optimizationOptions.indy = true
		it
	}

	GroovyShell shell = new GroovyShell(conf)

	GStringTemplateEngine gstringTemplateEngine = new GStringTemplateEngine(
	new GroovyClassLoader(GroovyELProvider.class.getClassLoader(), conf)
	)

	XmlTemplateEngine xmlTemplateEngine = new XmlTemplateEngine(new XmlParser(false, true), shell)  //TODO: Make configurable.


	private static int counter = 1;

	@Override
	Object eval(ValueStack valueStack, String expr, Class expectedType, String language)throws ELProviderException {

		try{
			switch(language){
				case "GroovyScript": return evalAsScript(valueStack, expr, expectedType)
				case "GString": return evalAsGString(valueStack, expr, expectedType)
				case "GStringTemplateInline": return evalAsGStringTemplate(valueStack, expr, expectedType)
				default: throw new ELProviderException("Groovy EL provider does not support language ${language}.")
			}
		} catch(GroovyRuntimeException ge) {
			throw new ELProviderException(ge)
		}
	}

	static Map<String, Template> gstringTemplates = new HashMap(); //TODO: Static? Cache eviction? ...

	private Object evalAsGStringTemplate(ValueStack contextMap, String expr, Class expectedType)throws ELProviderException {
		if(!expectedType.isAssignableFrom(String)){
			throw new ELProviderException("GStringTemplate is not allowed as expressions of type ${expectedType}");
		}
		
		
		Template template = gstringTemplates.get(expr) ?: gstringTemplateEngine.createTemplate((String) expr)
		gstringTemplates.put(expr, template)

		template.make(contextMap).toString()
		
	}

	private Object evalAsGString(ValueStack contextMap, String expr, Class expectedType)throws ELProviderException {
		return evalAsScript(contextMap, '"'+expr+'"', expectedType) //TODO: More escaping?

	}

	static Map<String, Script> scripts = new HashMap(); //TODO: Static? Cache eviction? ...

	private Object evalAsScript(ValueStack contextMap, String expr, Class expectedType)throws ELProviderException {

		//TODO: Caching
		Script script = scripts.get(expr) ?:  shell.parse(expr, "ELProviderScript" + counter++ + ".groovy");
		scripts.put(expr, script)

		def scriptObject = InvokerHelper.createScript(script.getClass(), new Binding(contextMap))


		def result = scriptObject.run();
		
		if(result==null){
			return null; //No type checks for null
		}

		if(expectedType == String){
			return result?.toString()
		}
		if(!expectedType.isInstance(result)){
			throw new ELProviderException("Cannot cast ${result} of type ${result?.getClass()} to ${expectedType}")
		}

		result;
		
	}

	@Override
	public String[] getSupportedLanguages() {
		// TODO Auto-generated method stub
		return [
			"GroovyScript",
			"GString",
			"GStringTemplateInline"
		];
	}

	//TODO: Das Caching kann nach ELSupport rausgezogen werden.
	
	//The 1st level cache. Valid from Processor.init till next...
	Map<URL, Script> templates = new HashMap() //TODO: Static, but looking if file has changed? Cache eviction? ...
	
	//The 2nd level cache. Uses lastModified timestamp
	//TODO Cache eviction, Concurrency etc.
	static Map<URL, Pair<Long, Script>> templatesStatic = new HashMap()

	@Override
	public void write(Writer writer, URL templateUrl, ValueStack valueStack, String templateLanguage, Long templateLastModified) {
		try{
			
			def template = templates.get(templateUrl)
			
			if( template == null && templateLastModified != null){
				
				def t = templatesStatic.get(templateUrl)
				//def ProcessingEnvironment pe = ExtensionRegistry.get(ProcessingEnvironment)
				//pe.messager.printMessage(Diagnostic.Kind.WARNING, "Groovy template for ${templateUrl} in static cache: ${t}. Last modified: ${templateLastModified}");
				if(t!=null && templateLastModified<=t.key){
					template = t.value
					templates.put(templateUrl, template)
				}
			}

			if (template == null){
				//def ProcessingEnvironment pe = ExtensionRegistry.get(ProcessingEnvironment)
				//pe.messager.printMessage(Diagnostic.Kind.WARNING, "Create Groovy template for ${templateUrl}. Cache: ${templates}");
				
				switch(templateLanguage){
					case "GStringTemplate": template = gstringTemplateEngine.createTemplate(templateUrl); break
					case "GroovyXmlTemplate":  template = xmlTemplateEngine.createTemplate(templateUrl); break

					default: throw new ELProviderException("Groovy EL provider does not support template language ${templateLanguage}.")
				}
				templates.put(templateUrl, template)
				templatesStatic.put(templateUrl, new Pair(System.currentTimeMillis(), template))
			}


			template.make(valueStack).writeTo(writer)

		} catch(GroovyRuntimeException ge) {
			throw new ELProviderException(ge)
		} 

	}

	@Override
	public String[] getSupportedTemplateLanguages() {
		return [
			"GroovyXmlTemplate",
			"GStringTemplate"
		];
	}


}
