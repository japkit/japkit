package de.stefanocke.japkit.roo.japkit.web;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.roo.base.web.WebMvcConfig;

@RuntimeMetadata
@SpringBootApplication
@Import(WebMvcConfig.class)
public class JapkitWebApplicationTemplate {
	
	@Method(imports=SpringApplication.class, bodyCode="SpringApplication.run(#{genClass.asType().code}.class, args);")
	public static void main(String[] args) {}
}
