package de.japkit.roo.japkit.web;

import org.springframework.format.FormatterRegistrar;
import org.springframework.format.FormatterRegistry;

import de.japkit.annotations.ParamNames;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.roo.base.web.EntityConverterUtil;
import de.japkit.roo.base.web.LabelProvider;

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
