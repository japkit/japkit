package de.stefanocke.japkit.roo.japkit;

import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;

@Template(vars = @Var(name = "toStringProperties", propertyFilter = @Properties(sourceClass = GeneratedClass.class)))
public abstract class ToString {
	@Method(imports = { ToStringBuilder.class, ToStringStyle.class },
			bodyExpr = "return new ToStringBuilder(this, ToStringStyle.SHORT_PREFIX_STYLE).\n"
					+ "<%toStringProperties.each{%>append(\"${it.simpleName}\", ${it.getter.simpleName}()).\n<%}%>" + "toString();\n",
			bodyLang = "GStringTemplateInline")
	public abstract String toString();
}
