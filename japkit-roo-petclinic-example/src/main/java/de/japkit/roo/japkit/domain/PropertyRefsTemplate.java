package de.japkit.roo.japkit.domain;

import javax.lang.model.element.Modifier;

import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.InnerClass;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Var;

@Template(vars=@Var(name="properties", expr="#{genClass.properties}"))
public class PropertyRefsTemplate {
	
	@Clazz(nameSuffixToRemove = "Def",
			nameSuffixToAppend = "Properties",
			modifiers = Modifier.PUBLIC)
	public static class PropertiesAuxClass{
		@InnerClass(src="properties", nameExpr="#{src.simpleName.toFirstUpper}_")
		public static final class PropertyName{}
		
		@Field(src="properties", nameExpr="#{src.simpleName.toString().toUpperCase()}", initCode="\"#{src.simpleName}\"")
		public static final String PROPERTYNAME = "propertyName";
		
		@Method
		void foo(){};
	}
	
}
