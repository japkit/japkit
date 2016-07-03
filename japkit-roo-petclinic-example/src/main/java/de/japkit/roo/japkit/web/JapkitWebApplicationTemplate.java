package de.japkit.roo.japkit.web;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Method;
import de.japkit.roo.base.web.WebMvcConfig;

@RuntimeMetadata
@SpringBootApplication
@Import(WebMvcConfig.class)
public class JapkitWebApplicationTemplate {
	
	@Method(imports=SpringApplication.class, bodyCode="SpringApplication.run(#{genClass.asType().code}.class, args);")
	public static void main(String[] args) {}
}
