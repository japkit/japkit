package de.japkit.metaannotations;

/**
 * The expression languages provided by japkit.
 * 
 * @author stefan
 */
public abstract class Lang {

	/**
	 * The Java Expression Language. This is the default expression language of
	 * Japkit. Whether Version 2.2 or 3 (JSR 341) is used depends on which EL Provider
	 * is on the classpath. japkit-all includes JUEL which is a V2.2 implementation.
	 * japkit-all-javael3 includes the EL implementation of Apache Tomcat 8,
	 * which is V3. It is possible to use other implementations. See pom.xml of
	 * japkit-all-javael3.
	 */
	public static final String JAVA_EL = "JavaEL";
	
	/**
	 * A Groovy script. The Groovy EL Provider must be on classpath. For example, see japkit-all.
	 */
	public static final String GROOVY = "GroovyScript";
	
	/**
	 * A String that is interpolated as described here: http://docs.groovy-lang.org/latest/html/documentation/#_double_quoted_string
	 * The Groovy EL Provider must be on classpath. For example, see japkit-all.
	 */
	public static final String GSTRING = "GString";
	
	/**
	 * A GString Template as described here: http://docs.groovy-lang.org/latest/html/api/groovy/text/GStringTemplateEngine.html
	 * 
	 * The Groovy EL Provider must be on classpath. For example, see japkit-all.
	 */
	public static final String GSTRING_TEMPLATE = "GStringTemplateInline";

}
