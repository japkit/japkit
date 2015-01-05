package de.stefanocke.japkit.roo.base.web;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.core.convert.converter.Converter;
import org.springframework.format.FormatterRegistry;
import org.springframework.ui.context.ThemeSource;
import org.springframework.ui.context.support.ResourceBundleThemeSource;
import org.springframework.web.servlet.ThemeResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;
import org.springframework.web.servlet.theme.CookieThemeResolver;
import org.springframework.web.servlet.view.tiles3.TilesConfigurer;
import org.springframework.web.servlet.view.tiles3.TilesViewResolver;

@Configuration
@ComponentScan
public class WebMvcConfig extends WebMvcConfigurerAdapter{
	/**
	 * Initialise Tiles on application startup and identify the location of the
	 * tiles configuration file, tiles.xml.
	 *
	 * @return tiles configurer
	 */
	@Bean
	public TilesConfigurer tilesConfigurer() {
		final TilesConfigurer configurer = new TilesConfigurer();
		configurer.setDefinitions(new String[] { "/WEB-INF/layouts/layouts.xml" });
		configurer.setCheckRefresh(true);
		return configurer;
	}

	/**
	 *
	 * @return tiles view resolver
	 */
	@Bean
	public TilesViewResolver tilesViewResolver() {
		return new TilesViewResolver();
	}
	
	@Bean
	public ReloadableResourceBundleMessageSource messageSource() throws Exception {
		ReloadableResourceBundleMessageSource ms = new ReloadableResourceBundleMessageSource();
		ms.setFallbackToSystemLocale(false);
		ms.setBasenames(resourceBundleNameRegistry().getObject());
		return ms;
	}
	
	@Bean 
	public ResourceBundleNameRegistry resourceBundleNameRegistry() {
		ResourceBundleNameRegistry r = new ResourceBundleNameRegistry();
		r.setCommon("application,messages");
		r.setPath("WEB-INF/i18n/");
		return r;
	}
	
	@Bean
	public ThemeSource themeSource(){
		return new ResourceBundleThemeSource();
	}
	
	@Bean
	public ThemeResolver themeResolver(){
		CookieThemeResolver resolver = new CookieThemeResolver();
		resolver.setDefaultThemeName("standard");
		resolver.setCookieName("theme");
		return resolver;
	}
	
	@Bean
	public Converters converters(){
		return new Converters();
	}; 
	
	@Override
	public void addFormatters(FormatterRegistry registry) {
		converters().registerConverters(registry);
	}
	
}
