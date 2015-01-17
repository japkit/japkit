package de.stefanocke.japkit.roo.japkit.web;

import org.springframework.format.FormatterRegistrar;
import org.springframework.format.FormatterRegistry;

import de.stefanocke.japkit.annotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.roo.base.web.EntityConverterUtil;
import de.stefanocke.japkit.roo.base.web.LabelProvider;

@Template
public abstract class ControllerFormatterMembers implements FormatterRegistrar, LabelProvider<FormBackingObject> {
	

		@Method(imports={EntityConverterUtil.class} ,
				bodyCode="EntityConverterUtil.registerConverters(#{fbo.name}.class, registry, crudOperations(), this);")
		@ParamNames("registry")
		@Override
		public void registerFormatters(FormatterRegistry registry) {
			//EntityConverterUtil.registerConverters(FormBackingObject.class, registry, crudOperations(), this);		
		}
		
		
		//TODO
		@Method(bodyCode="return \"ID: \" + entity.getId();")
		@Override
		@ParamNames("entity")
		public String getLabel(FormBackingObject entity) {
			return null;
		}	

	
}
