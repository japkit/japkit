package de.japkit.metaannotations;

/**
 * The template languages provided by Japkit. The difference between template
 * languages and expression languages (see {@link Lang}) are:
 * <ul>
 * <li>Templates written in template languages are always separate files.
 * Expressions in expression languages are always part of a Java template class.
 * <li>Template languages are only used in {@link ResourceTemplate} and generate
 * always separate files by streaming the result of the template evaluation.
 * Expression do not stream. They are evaluated to a String or another value
 * which can be used in other expressions or in method bodies.
 * </ul>
 * 
 * @author stefan
 */
public abstract class TemplateLang {
	/**
	 * A GString Template as described here: http://docs.groovy-lang.org/latest/html/api/groovy/text/GStringTemplateEngine.html
	 * The Groovy EL Provider must be on classpath. For example, see japkit-all.
	 */
	public static final String GSTRING_TEMPLATE = "GStringTemplate";
	
	/**
	 * A Groovy XML Template as described here: http://docs.groovy-lang.org/latest/html/api/groovy/text/XmlTemplateEngine.html
	 * The Groovy EL Provider must be on classpath. For example, see japkit-all.
	 */
	public static final String GROOVY_XML_TEMPLATE = "GroovyXmlTemplate";

}
