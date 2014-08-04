package de.stefanocke.japkit.roo.japkit;

import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import de.stefanocke.japkit.metaannotations.Case;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.TypeCategory;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;

@Template(vars = @Var(name = "toStringProperties", propertyFilter = @Properties(sourceClass = GeneratedClass.class)))
public abstract class ToString {
	@Method(imports = { ToStringBuilder.class, ToStringStyle.class },
			
			bodyIterator="#{toStringProperties}",
			//bodyIteratorVar="p"
			bodyBeforeIteratorCode = "return new ToStringBuilder(this, ToStringStyle.SHORT_PREFIX_STYLE).\n",
			
			bodyCases={
				//Only summary for collections
				@Case(matcher=@Matcher(typeCategory=TypeCategory.COLLECTION), 
						expr = "append(\"#{src.simpleName}\", #{src.getter.simpleName}(), false).\n"),
			},
			bodyCode = "append(\"#{src.simpleName}\", #{src.getter.simpleName}()).\n",
			bodyAfterIteratorCode = "toString();\n",
			bodyEmptyIteratorCode = "return super.toString();" 
			)
	public abstract String toString();
	
	//idea: Fragments could be written as classes:
	
	/**
	 * @japkit.expr <code>append("#{src.simpleName}", #{src.getter.simpleName}(), false).</code>
	 */
	@CodeFragment(activation=@Matcher(typeCategory=TypeCategory.COLLECTION))
	class AppendCollection{}
	
}
