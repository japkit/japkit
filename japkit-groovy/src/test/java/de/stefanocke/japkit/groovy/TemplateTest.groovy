package de.stefanocke.japkit.groovy

import java.util.Map;
import java.util.concurrent.TimeUnit;

import javax.lang.model.element.TypeElement;
import javax.lang.model.type.TypeMirror;

import com.google.common.base.Stopwatch
import de.stefanocke.japkit.support.el.ElExtensionPropertiesAndMethods;
import groovy.text.GStringTemplateEngine;
import org.eclipse.xtext.xbase.lib.Functions
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.Functions.Function2;
import org.eclipse.xtext.xbase.lib.Functions.Function4;
import org.junit.Ignore;


class TemplateTest extends GroovyTestCase{
	
	
	void testSingleValueExtension(){
		println "" + [].singleValue
	}
}
