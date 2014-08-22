package de.stefanocke.japkit.metaannotations;

@Deprecated
public @interface Members {
	
	String _prefix() default "members";
	
	/**
	 * Optional matcher to switch on / off the generation of the members.
	 * @return
	 */
	Matcher[] activation() default {}; 
	
	/**
	 * 
	 * @return the class with the member annotations. Void means that the trigger annotation class is searched for member annotations. 
	 */
	Class<?> value() default void.class;
}
