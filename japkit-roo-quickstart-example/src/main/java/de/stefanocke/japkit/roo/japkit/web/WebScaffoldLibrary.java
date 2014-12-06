package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.Function;

public class WebScaffoldLibrary {
	/**
	 * @japkit.expr <pre>
	 * <code>
	 * def pNames;  
	 * pNames={p, prfx -> 
	 * 	p.collect{
	 * 		def name = prfx ? prfx+'.'+it.name : it.name;
	 * 		def names = [name];
	 * 		if(it.isVO || it.isDTO)  names.addAll(pNames(it.asType().asElement.properties, name));
	 *	 	names
	 * 	}.flatten()
	 * };
	 * pNames(src, null)
	 * </code>
	 * </pre>
	 */
	@Function(lang = "GroovyScript")
	class allPropertyNames {}
}
