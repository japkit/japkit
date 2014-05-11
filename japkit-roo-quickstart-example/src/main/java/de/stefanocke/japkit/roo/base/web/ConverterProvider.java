package de.stefanocke.japkit.roo.base.web;

import org.springframework.core.convert.converter.ConverterRegistry;

public interface ConverterProvider {

	void registerConverters(ConverterRegistry registry);

}