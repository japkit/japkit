package de.stefanocke.japkit.el;

import java.io.Writer;
import java.net.URL;

import de.stefanocke.japkit.el.ELProviderException;
import de.stefanocke.japkit.el.ValueStack;

public interface ELProvider {
	

	Object eval(ValueStack contextMap, String expr, Class<?> expectedType, String language) throws ELProviderException;
	
	String[] getSupportedLanguages();
	
	void write(Writer writer, URL templateUrl, ValueStack contextMap, String templateLanguage, Long templateLastModified);
	
	String[] getSupportedTemplateLanguages();
}
