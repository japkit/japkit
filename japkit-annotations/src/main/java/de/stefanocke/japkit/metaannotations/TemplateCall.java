package de.stefanocke.japkit.metaannotations;

/**Calls a Java template to contribute members to the generated class.*/
public @interface TemplateCall {
	
	/**
	 * By default, this annotation is active an will call the template.
	 * To switch it on or of case by case, a Matcher can be used here.
	 * <p>
	 * In case of multiple matchers, at least one must match to activate the
	 * rule.
	 * 
	 * @return
	 */
	Matcher[] activation() default {}; 
	
	/**
	 * 
	 * @return the template class 
	 */
	Class<?> value();
}
