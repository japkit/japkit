package de.japkit.roo.japkit.domain;

import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import de.japkit.metaannotations.Case;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.TypeCategory;
import de.japkit.metaannotations.Var;

@Template(vars = @Var(name = "toStringProperties", expr="#{genClass.properties}"))
public abstract class ToString {
	
	//Idea:
	//@TemplateParams
	//void params(List<Property> properties)
	
	@Method(imports = { ToStringBuilder.class, ToStringStyle.class },
			
			bodyIterator="#{toStringProperties}",
			//bodyIteratorVar="p"
			bodyBeforeIteratorCode = "return new ToStringBuilder(this, ToStringStyle.SHORT_PREFIX_STYLE).",
			
			bodyCases={
				//Only summary for collections
				@Case(cond="isCollection", 
						value = "append(\"#{src.simpleName}\", #{src.getter.simpleName}(), false)."),
			},
			bodyCode = "append(\"#{src.simpleName}\", #{src.getter.simpleName}()).",
			bodyAfterIteratorCode = "toString();",
			bodyEmptyIteratorCode = "return super.toString();",
			bodyIndentAfterLinebreak=true
			)
	public abstract String toString();
	
//	//idea: Fragments could be written as classes:
//	
//	/**
//	 * @japkit.expr <code>append("#{src.simpleName}", #{src.getter.simpleName}(), false).</code>
//	 */
//	@CodeFragment(activation=@Matcher(typeCategory=TypeCategory.COLLECTION))
//	class AppendCollection{}
	
}
