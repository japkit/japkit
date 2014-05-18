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
			
			bodyIterator="#{toStringProperties}",
			//bodyIteratorVar="p"
			bodyBeforeExpr = "return new ToStringBuilder(this, ToStringStyle.SHORT_PREFIX_STYLE).\n",
			bodyExpr = "append(\"#{element.simpleName}\", #{element.getter.simpleName}()).\n",
			//Idee: Switch-Support.
			//bodyExpr1Activation =
			//bodyExpr1=
			//bodyExpr1Activation =
			//bodyExpr1=
			bodyAfterExpr = "toString();\n",
			bodyEmptyExpr = "return super.toString();" 
			)
	public abstract String toString();
}
