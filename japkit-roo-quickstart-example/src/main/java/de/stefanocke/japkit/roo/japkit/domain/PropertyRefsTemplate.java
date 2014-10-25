package de.stefanocke.japkit.roo.japkit.domain;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.InnerClass;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.AnnotatedClass;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;

@Template(vars=@Var(name="properties", propertyFilter=@Properties(sourceClass=GeneratedClass.class)))
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
