package de.japkit.roo.base.web;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.format.FormatterRegistry;
import org.springframework.ui.context.ThemeSource;
import org.springframework.ui.context.support.ResourceBundleThemeSource;
import org.springframework.web.servlet.ThemeResolver;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;
import org.springframework.web.servlet.theme.CookieThemeResolver;
import org.springframework.web.servlet.view.tiles3.TilesConfigurer;
import org.springframework.web.servlet.view.tiles3.TilesViewResolver;

@Configuration
@ComponentScan
public class WebMvcConfig extends WebMvcConfigurerAdapter{
	/**
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
	public Formatters formatters(){
		return new Formatters();
	} 
	
	@Override
	public void addFormatters(FormatterRegistry registry) {
		formatters().registerConverters(registry);
	}
	
	@Override
	public void addViewControllers(ViewControllerRegistry registry) {
		registry.addViewController("/").setViewName("index");
	}
	
}
