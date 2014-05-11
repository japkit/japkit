package de.stefanocke.japkit.roo.japkit.web;

import org.springframework.core.convert.converter.ConverterRegistry;

import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.roo.base.web.ConverterProvider;
import de.stefanocke.japkit.roo.base.web.CrudOperations;
import de.stefanocke.japkit.roo.base.web.EntityConverterUtil;
import de.stefanocke.japkit.roo.base.web.LabelProvider;

@Template
public abstract class ControllerConverterProviderMembers implements ConverterProvider, LabelProvider<FormBackingObject> {
	
	@Method(imports={EntityConverterUtil.class} ,
			bodyExpr="EntityConverterUtil.registerConverters(#{ec.typeRef(fbo)}.class, registry, crudOperations(), this);")
	@Override
	public void registerConverters(ConverterRegistry registry) {
		EntityConverterUtil.registerConverters(FormBackingObject.class, registry, crudOperations(), this);		
	}
	
	
	@Method(bodyExpr="return \"foobar\";")
	@Override
	public String getLabel(FormBackingObject entity) {
		return null;
	}	

	abstract CrudOperations<FormBackingObject> crudOperations();

}
