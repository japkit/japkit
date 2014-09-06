package de.stefanocke.japkit.support.el;

import java.io.Writer;
import java.net.URL;

public interface ELProvider {
	

	Object eval(ValueStack contextMap, String expr, Class<?> expectedType, String language) throws ELProviderException;
	
	String[] getSupportedLanguages();
	
	void write(Writer writer, URL templateUrl, ValueStack contextMap, String templateLanguage, Long templateLastModified);
	
	String[] getSupportedTemplateLanguages();
}
