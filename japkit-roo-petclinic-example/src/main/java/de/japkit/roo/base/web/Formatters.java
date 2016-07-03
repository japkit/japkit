package de.japkit.roo.base.web;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.convert.converter.Converter;
import org.springframework.format.FormatterRegistrar;
import org.springframework.format.FormatterRegistry;

public class Formatters {
	@Autowired(required=false)
	private List<FormatterRegistrar> formatterRegistrars = new ArrayList<FormatterRegistrar>();
	
	public void registerConverters(FormatterRegistry registry){
		for (FormatterRegistrar provider : formatterRegistrars) {
			provider.registerFormatters(registry);	
		}
		registry.addConverter(new Converter<Object, String>() {

			@Override
			public String convert(Object source) {
				return source.toString();
			}
		});
	}
}
