package de.stefanocke.japkit.roo.base.web;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.convert.converter.Converter;
import org.springframework.core.convert.converter.ConverterRegistry;

public class Converters {
	@Autowired(required=false)
	private List<ConverterProvider> converterProviders = new ArrayList<ConverterProvider>();
	
	public void registerConverters(ConverterRegistry registry){
		for (ConverterProvider provider : converterProviders) {
			provider.registerConverters(registry);	
		}
		registry.addConverter(new Converter<Object, String>() {

			@Override
			public String convert(Object source) {
				return source.toString();
			}
		});
	}
}
