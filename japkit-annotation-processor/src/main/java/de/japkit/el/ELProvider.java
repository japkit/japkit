package de.japkit.el;

import java.io.Writer;
import java.net.URL;
import java.util.List;

public interface ELProvider {
	
	Object eval(ValueStack contextMap, String expr, Class<?> expectedType, String language, List<String> importedClasses) throws ELProviderException;	
	
	String[] getSupportedLanguages();
	
	void write(Writer writer, URL templateUrl, ValueStack contextMap, String templateLanguage, Long templateLastModified);
	
	String[] getSupportedTemplateLanguages();
}
