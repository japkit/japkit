package de.stefanocke.japkit.roo.japkit.web;

import org.springframework.core.convert.converter.ConverterRegistry;

import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.roo.base.web.ConverterProvider;
import de.stefanocke.japkit.roo.base.web.CrudOperations;
import de.stefanocke.japkit.roo.base.web.EntityConverterUtil;
import de.stefanocke.japkit.roo.base.web.LabelProvider;

@Template
public abstract class ControllerConverterProviderMembers implements ConverterProvider, LabelProvider<FormBackingObject> {
	
	@Method(imports={EntityConverterUtil.class} ,
			bodyCode="EntityConverterUtil.registerConverters(#{ec.typeRef(fbo)}.class, registry, crudOperations(), this);")
	@ParamNames("registry")
	@Override
	public void registerConverters(ConverterRegistry registry) {
		EntityConverterUtil.registerConverters(FormBackingObject.class, registry, crudOperations(), this);		
	}
	
	
	//TODO
	@Method(bodyCode="return \"ID: \" + entity.getId();")
	@Override
	@ParamNames("entity")
	public String getLabel(FormBackingObject entity) {
		return null;
	}	

	abstract CrudOperations<FormBackingObject> crudOperations();

}
