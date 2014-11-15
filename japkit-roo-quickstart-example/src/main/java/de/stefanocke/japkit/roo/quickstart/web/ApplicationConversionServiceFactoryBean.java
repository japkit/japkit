package de.stefanocke.japkit.roo.quickstart.web;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.convert.converter.Converter;
import org.springframework.format.FormatterRegistry;
import org.springframework.format.support.FormattingConversionServiceFactoryBean;

import de.stefanocke.japkit.roo.base.web.ConverterProvider;

//@Configurable
/**
 * A central place to register application converters and formatters. 
 */
public class ApplicationConversionServiceFactoryBean extends FormattingConversionServiceFactoryBean {

	@Autowired(required=false)
	private List<ConverterProvider> converterProviders = new ArrayList<ConverterProvider>();
	
	
	@Override
	protected void installFormatters(FormatterRegistry registry) {
		super.installFormatters(registry);
		// Register application converters and formatters
	}

	public void installLabelConverters(FormatterRegistry registry) {
		for (ConverterProvider provider : converterProviders) {
			provider.registerConverters(registry);	
		}
		//Q&D: toString() as fallback 
		registry.addConverter(new Converter<Object, String>() {

			@Override
			public String convert(Object source) {
				return source.toString();
			}
		});
	}

	public void afterPropertiesSet() {
		super.afterPropertiesSet();
		installLabelConverters(getObject());
	}


}
