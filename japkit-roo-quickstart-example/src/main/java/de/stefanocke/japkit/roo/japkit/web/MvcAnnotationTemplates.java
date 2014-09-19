package de.stefanocke.japkit.roo.japkit.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import de.stefanocke.japkit.roo.japkit.meta.AnnotationTemplates;

@AnnotationTemplates(targetAnnotations = {RequestMapping.class, Controller.class})
public class MvcAnnotationTemplates {
	
	
}
