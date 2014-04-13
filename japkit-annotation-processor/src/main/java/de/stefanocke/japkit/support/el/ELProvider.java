package de.stefanocke.japkit.support.el;

import java.io.Writer;
import java.net.URL;
import java.util.Map;

public interface ELProvider {
	
	@SuppressWarnings("rawtypes") //Xtend has sometimes issues with wildcard types...
	Object eval(Map contextMap, String expr, Class expectedType, String language) throws ELProviderException;
	
	String[] getSupportedLanguages();
	
	void write(Writer writer, URL templateUrl, Map contextMap, String templateLanguage, Long templateLastModified);
	
	String[] getSupportedTemplateLanguages();
}
